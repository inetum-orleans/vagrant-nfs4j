# vagrant-nfs4j

[![](https://img.shields.io/gem/v/vagrant-nfs4j.svg)](https://rubygems.org/gems/vagrant-nfs4j)

A Vagrant plugin that brings support of 
[Vagrant NFS Synced Folders](https://www.vagrantup.com/docs/synced-folders/nfs.html) to Windows hosts with 
[nfs4j-daemon](https://github.com/gfi-centre-ouest/nfs4j-daemon) under the hood.

This project is heavily inspired by [vagrant-winnfsd](https://github.com/winnfsd/vagrant-winnfsd).

## Quickstart

- Install the plugin
```
vagrant plugin install vagrant-nfs4j
```

- Configure nfs synced folders in `Vagrantfile`

```ruby
Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'

  config.vm.synced_folder 'C:\Users\Toilal', # Host Path 
                          '/user', # VM Path
                          id: 'user',
                          type: 'nfs',
                          mount_options: %w(uid=1000 gid=1000)
end
```

## Configuration

See [lib/vagrant-nfs4j/config/nfs4j.rb](https://github.com/gfi-centre-ouest/vagrant-nfs4j/blob/master/lib/vagrant-nfs4j/config/nfs4j.rb)
for options available in `config.nfs4j` object of `Vagrantfile`.