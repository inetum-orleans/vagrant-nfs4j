require 'vagrant'
require_relative 'utils'
require Vagrant.source_root.join("plugins/synced_folders/nfs/synced_folder")

module VagrantNfs4j
  class SyncedFolder < VagrantPlugins::SyncedFolderNFS::SyncedFolder
    def enable(machine, folders, nfsopts)
      raise Vagrant::Errors::NFSNoHostIP unless nfsopts[:nfs_host_ip]
      raise Vagrant::Errors::NFSNoGuestIP unless nfsopts[:nfs_machine_ip]

      if machine.guest.capability?(:nfs_client_installed)
        installed = machine.guest.capability(:nfs_client_installed)
        unless installed
          can_install = machine.guest.capability?(:nfs_client_install)
          raise Vagrant::Errors::NFSClientNotInstalledInGuest unless can_install
          machine.ui.info I18n.t("vagrant.actions.vm.nfs.installing")
          machine.guest.capability(:nfs_client_install)
        end
      end

      machine_ip = nfsopts[:nfs_machine_ip]
      machine_ip = [machine_ip] unless machine_ip.is_a?(Array)

      # Keep nfs_version and nfs_udp configured by user to remove default
      # vers=3,udp options
      config_nfs_versions = {}
      config_nfs_udps = {}
      folders.each do |id, opts|
        config_nfs_versions[id] = opts[:nfs_version]
        config_nfs_udps[id] = opts[:nfs_udp]
      end

      # Prepare the folder, this means setting up various options
      # and such on the folder itself.
      folders.each {|id, opts| prepare_folder(machine, opts)}

      # Restore configured nfs_version
      folders.each do |id, opts|
        opts[:nfs_udp] = config_nfs_udps[id]
        opts[:nfs_version] = config_nfs_versions[id]
        unless opts[:nfs_version]
          # Use nfs v4.1 as default version
          opts[:nfs_version] = '4.1'
        end
      end

      # Determine what folders we'll export
      export_folders = folders.dup
      export_folders.keys.each do |id|
        opts = export_folders[id]
        if opts.has_key?(:nfs_export) && !opts[:nfs_export]
          export_folders.delete(id)
        end
      end

      # Export the folders. We do this with a class-wide lock because
      # NFS exporting often requires sudo privilege and we don't want
      # overlapping input requests. [GH-2680]
      @@lock.synchronize do
        begin
          machine.env.lock("nfs-export") do
            machine.ui.info I18n.t("vagrant.actions.vm.nfs.exporting")
            machine.env.host.capability(
                :nfs_export,
                machine, machine_ip, export_folders)
          end
        rescue Vagrant::Errors::EnvironmentLockedError
          sleep 1
          retry
        end
      end

      # Mount
      machine.ui.info I18n.t("vagrant.actions.vm.nfs.mounting")

      # Only mount folders that have a guest path specified.
      mount_folders = {}
      folders.each do |id, opts|
        opts = opts.dup

        real_hostpath = opts[:hostpath]
        if Vagrant::Util::Platform.windows?
          opts[:hostpath] = VagrantNfs4j::Utils.prefix_alias(machine, opts[:guestpath])
        end

        opts[:mount_options] = VagrantNfs4j::Utils.apply_mount_options(opts[:mount_options])

        machine.ui.detail(I18n.t('vagrant.actions.vm.share_folders.mounting_entry',
                                 guestpath: opts[:guestpath],
                                 hostpath: real_hostpath))

        mount_folders[id] = opts
      end

      # Allow override of the host IP via config.
      # TODO: This should be configurable somewhere deeper in Vagrant core.
      host_ip = nfsopts[:nfs_host_ip]

      if (!machine.config.nfs4j.host_ip.empty?)
        host_ip = machine.config.nfs4j.host_ip
      end

      # Mount them!
      machine.guest.capability(
          :mount_nfs_folder, host_ip, mount_folders)
    end
  end
end
