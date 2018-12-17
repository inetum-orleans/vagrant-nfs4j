module VagrantNfs4j
  class Utils
    def self.hostpath_to_share_path(hostpath)
      path = hostpath.dup
      path.gsub!("'", "'\\\\''")
      path.gsub!('/', '\\')
      return path
    end

    def self.hostpath_to_share_alias(hostpath)
      path = hostpath.dup
      return "/#{path.gsub(':', '').gsub('\\', '/')}"
    end

    def self.prefix_alias(machine, share_alias)
      if share_alias.start_with? '/'
        return "/#{machine.id}#{share_alias}"
      else
        return "/#{machine.id}/#{share_alias}"
      end
    end

    def self.get_share_alias_machine_id(share_alias)
      matches = /\/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})(?:\/|\z)/.match(share_alias)
      if matches
        return matches.captures[0]
      end
    end

    def self.apply_mount_options(mount_options, share = nil)
      if mount_options
        to_delete = []
        mount_options.each_with_index do |opt, i|
          uid = nil
          uid_matches = /uid=(\d+)/.match(opt)
          if uid_matches
            uid = /uid=(\d+)/.match(opt).captures[0].to_i
            to_delete.push(i)
          end

          if uid and share
            unless share['permissions']
              share['permissions'] = {}
            end
            share['permissions']['uid'] = uid
          end

          gid = nil
          gid_matches = /gid=(\d+)/.match(opt)
          if gid_matches
            to_delete.push(i)
            gid = gid_matches.captures[0].to_i
          end

          if gid and share
            unless share['permissions']
              share['permissions'] = {}
            end
            share['permissions']['gid'] = gid
          end
        end

        to_delete.reverse.each do |i|
          mount_options.delete_at(i)
        end
      end

      return mount_options
    end

    def self.which(cmd, more_paths = [])
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      exts = exts.map {|e| e.downcase }

      path = [more_paths, *ENV['PATH'].split(File::PATH_SEPARATOR)].flatten.map {|path| path.gsub(/\\/, '/')}
      path.each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      return nil
    end
  end
end