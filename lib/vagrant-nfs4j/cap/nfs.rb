require 'yaml/store'
require 'net/http'
require_relative '../nfs4j_daemon/wrapper'
require_relative '../utils'

require Vagrant.source_root.join('plugins/hosts/windows/cap/nfs')

module VagrantNfs4j
  module Cap
    class NFS < Vagrant.plugin('2', :host)
      def self.nfs_export(environment, machine, ips, folders)
        config = machine.config.nfs4j
        api_port = config.api_port
        wrapper = VagrantNfs4j::Nfs4jDaemon::Wrapper.new(api_port)

        shares = {}
        status = wrapper.status()
        if status and status['shares']
          status['shares'].each do |share|
            shares[share['alias']] = share
          end
        end

        wrapper.setup_firewall(machine.ui, config.setup_firewall, config.java_home)

        wrapper.start(machine.ui,
                      config.daemon_start,
                      config.daemon_exe,
                      config.daemon_jar,
                      config.daemon_opts,
                      config.java_home,
                      config.java_opts)

        folders.each do |k, opts|
          share = machine.config.nfs4j.shares_config.merge({})

          opts[:mount_options] = VagrantNfs4j::Utils.apply_mount_options(opts[:mount_options], share)

          share[:path] = VagrantNfs4j::Utils.hostpath_to_share_path(opts[:hostpath])
          share[:alias] = VagrantNfs4j::Utils.prefix_alias(machine, opts[:guestpath])

          existing_share = shares[share[:alias]]
          if existing_share
            machine.ui.detail(I18n.t('vagrant_nfs4j.cap.nfs_export.detaching_existing_share',
                                     path: existing_share[:path],
                                     alias: existing_share[:alias]))

            wrapper.detach(existing_share)
          end

          machine.ui.detail(I18n.t('vagrant_nfs4j.cap.nfs_export.attaching_share',
                                   path: share[:path],
                                   alias: share[:alias]))
          wrapper.attach(share)
        end
      end

      def self.nfs_prune(environment, ui, valid_ids)
        wrapper = VagrantNfs4j::Nfs4jDaemon::Wrapper.new()

        status = wrapper.status()
        if status and status['shares']
          status['shares'].each do |share|
            share_machine_id = VagrantNfs4j::Utils.get_share_alias_machine_id(share['alias'])
            if share_machine_id and not valid_ids.include? share_machine_id
              machine.ui.detail(I18n.t('vagrant_nfs4j.cap.nfs_prune.pruning_share',
                                       path: share['path'],
                                       alias: share['alias']))
              wrapper.detach(share)
            end
          end
        end
      end

      def self.nfs_installed(environment)
        true
      end
    end
  end
end
