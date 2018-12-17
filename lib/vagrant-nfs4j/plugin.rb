begin
  require 'vagrant'
rescue LoadError
  raise "The Vagrant nfs4j plugin must be run within Vagrant."
end

if Vagrant::VERSION < "1.5.0"
  raise "The Vagrant nfs4j plugin is only compatible with Vagrant 1.5.0+"
end


module VagrantNfs4j
  class Plugin < Vagrant.plugin('2')
    name 'vagrant-nfs4j'

    description <<-DESC
    Brings support of Vagrant NFS Synced Folders to Windows with nfs4j-daemon under the hood.
    DESC

    action_hook(:init_i18n, :environment_load) {init_plugin}

    config('vm') do
      require_relative 'config/config'
      @config = VagrantNfs4j::Config::Config
    end

    config(:nfs4j) do
      require_relative 'config/nfs4j'
      VagrantNfs4j::Config::Nfs4j
    end

    synced_folder('nfs') do
      require_relative 'synced_folder'
      VagrantNfs4j::SyncedFolder
    end

    host_capability('windows', 'nfs_export') do
      require_relative 'cap/nfs'
      Cap::NFS
    end

    host_capability('windows', 'nfs_installed') do
      require_relative 'cap/nfs'
      Cap::NFS
    end

    host_capability('windows', 'nfs_prune') do
      require_relative 'cap/nfs'
      Cap::NFS
    end


    def self.init_plugin
      I18n.load_path << File.expand_path('locales/en.yml', VagrantNfs4j.source_root)
      I18n.reload!
    end
  end
end
