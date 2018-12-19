# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

###############################
# General project settings
# -----------------------------
box_name = 'ubuntu/xenial64'

require 'yaml'

current_dir = File.dirname(File.expand_path(__FILE__))
config_file = YAML.load_file("#{current_dir}/config.yaml")

ip_address = config_file['ip_address'] || '192.168.1.100'

if config_file['ssh'].nil? || config_file['ssh']['username'].nil?
  ssh_username = 'vagrant'
else
  ssh_username = config_file['ssh']['username']
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = box_name

  config.vm.network 'private_network', ip: ip_address, use_dhcp_assigned_default_route: true

  synced_folders = config_file['synced_folders']
  if Vagrant.has_plugin?('vagrant-nfs4j') and synced_folders
    synced_folders.each do |id, folder|
      mount_options = if folder.key?('mount_options') then
                        folder['mount_options']
                      else
                        %w(noatime nodiratime actimeo=1)
                      end
      mount_options = if not mount_options or mount_options.kind_of?(Array) then
                        mount_options
                      else
                        mount_options.split(/[,\s]/)
                      end

      mount_options.push('uid=1000')
      mount_options.push('gid=1000')

      source = "#{folder['source']}"
      target = if folder['target'].start_with?("/") then
                 folder['target']
               else
                 "/home/#{ssh_username}/#{folder['target']}"
               end

      config.vm.synced_folder source, target,
                              id: "#{id}",
                              type: 'nfs',
                              mount_options: mount_options
    end
  end
end
