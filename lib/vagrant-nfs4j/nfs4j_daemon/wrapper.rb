require 'rest-client'
require 'json'
require 'fileutils'

require_relative 'errors'
require_relative '../utils'

module VagrantNfs4j
  module Nfs4jDaemon
    class Wrapper
      def initialize(api_port = nil, api_bearer = nil)
        @api_port = api_port
        @api_bearer = api_bearer

        @exe = VagrantNfs4j.get_path_for_file('nfs4j-daemon.exe')
        @jar = VagrantNfs4j.get_path_for_file('nfs4j-daemon.jar')

        @port_file = "#{Vagrant.user_data_path}/nfs4j.port"
        if !@api_port and File.exist?(@port_file)
          port_file_data = File.read(@port_file);
          @api_port = port_file_data.to_i
        elsif @api_port
          File.write(@port_file, @api_port.to_s)
        end

        @bearer_file = "#{Vagrant.user_data_path}/nfs4j.bearer"
        if !@api_bearer and File.exist?(@bearer_file)
          bearer_file_data = File.read(@bearer_file);
          @api_bearer = bearer_file_data
        elsif @api_bearer
          File.write(@port_file, @api_port.to_s)
        elsif File.exist?(@bearer_file)
          File.delete(@bearer_file)
        end

        @setup_firewall_script = "#{Vagrant.user_data_path}/tmp/nfs4j.setup_firewall.bat"
      end

      def setup_firewall(ui, setup_firewall, java_home)
        java_exe = if java_home
                     additional_path = File.join(java_home, 'bin')
                     VagrantNfs4j::Utils.which("java", additional_path)
                   else
                     VagrantNfs4j::Utils.which("java")
                   end

        java_exe = java_exe.gsub('/', '\\')

        ports = [2049, @api_port]

        rule_name = "vagrant-nfs4j-#{VagrantNfs4j::VERSION}-#{java_exe}-tcp-#{ports.join(',')}".gsub('\\', '-').gsub(':', '')
        rule_exist = "netsh advfirewall firewall show rule name=\"#{rule_name}\">nul"

        unless system(sprintf(rule_exist, rule_name))


          rule_template = "netsh advfirewall firewall add rule name=\"%s\" dir=\"%s\" action=allow protocol=TCP localport=#{ports.join(',')} program=\"%s\" profile=any"

          all_rules = []
          all_rules.push("netsh advfirewall firewall delete rule name=\"#{rule_name}\"")
          all_rules.push(sprintf(rule_template, rule_name, 'in', java_exe))
          all_rules.push(sprintf(rule_template, rule_name, 'out', java_exe))

          setup_firewall_template_script = VagrantNfs4j.get_path_for_file('request_uac_header.bat')
          File.delete(@setup_firewall_script) if File.exist?(@setup_firewall_script)
          FileUtils.cp(setup_firewall_template_script, @setup_firewall_script)
          open(@setup_firewall_script, 'a') do |f|
            all_rules.each do |rule|
              f.puts rule
            end
          end

          if setup_firewall
            ui.detail(I18n.t('vagrant_nfs4j.nfs4j_daemon.installing_firewall_rule', rule_name: rule_name))

            setup_firewall_script_response = system(@setup_firewall_script)
            File.delete(@setup_firewall_script) if File.exist?(@setup_firewall_script)

            if setup_firewall_script_response
              ui.detail(I18n.t('vagrant_nfs4j.nfs4j_daemon.firewall_rule_installed', rule_name: rule_name))
            else
              ui.detail(I18n.t('vagrant_nfs4j.nfs4j_daemon.firewall_error'))
              all_rules.each do |rule|
                puts rule
              end
            end
          else
            ui.detail(I18n.t('vagrant_nfs4j.nfs4j_daemon.firewall_manual'))
            all_rules.each do |rule|
              puts rule
            end
          end
        end
      end

      def is_running(should_raise_start_failed = false, ui = nil)
        unless @api_port
          return false
        end
        begin
          r = RestClient::Request.execute method: :get, url: "http://127.0.0.1:#{@api_port}/ping", headers: {accept: :json}.merge(self.headers()), timeout: 5
          data = JSON.parse(r.body)
          return data === 'pong'
        rescue
          if should_raise_start_failed
            raise StartFailed
          end
          if ui
            if $!.is_a?(RestClient::Exceptions::Timeout)
              raise TimeoutError
            end
          end
          ui.detail(I18n.t('vagrant_nfs4j.nfs4j_daemon.check_has_failed_retrying', {:cause => Nfs4jDaemonErrors.get_message($!)})) if ui
        end
        false
      end

      def get_cmd_base(exe, jar, java_home, java_opts)
        cmd_base = if exe
                     "\"#{exe.is_a?(String) ? VagrantNfs4j::Utils.which(exe) : @exe}\""
                   else
                     if not java_opts
                       java_opts = ""
                     else
                       java_opts = " #{java_opts}"
                     end

                     java_exe = if java_home
                                  additional_path = File.join(java_home, 'bin')
                                  "\"#{VagrantNfs4j::Utils.which("java", additional_path)}\""
                                else
                                  "\"#{VagrantNfs4j::Utils.which("java")}\""
                                end
                     jar.is_a?(String) ? "#{java_exe}#{java_opts} -jar #{jar}" : "#{java_exe}#{java_opts} -jar #{@jar}"
                   end
        cmd_base
      end

      def start(ui, start, exe, jar, cmd, opts, java_home, java_opts)
        unless start
          unless self.is_running()
            raise Nfs4jUnavailable.new({api_port: @api_port})
          end
        end

        if self.is_running()
          ui.detail(I18n.t('vagrant_nfs4j.nfs4j_daemon.is_already_running'))
          return false
        end

        if cmd
          cmd_base = cmd
        else
          cmd_base = self.get_cmd_base(exe, jar, java_home, java_opts)
        end

        if opts
          opts = " #{opts}"
        else
          opts = ""
        end

        if @api_bearer
          opts = " --api-bearer=#{@api_bearer}#{opts}"
        end
        opts = " --api-ip=127.0.0.1#{opts}"
        opts = " --api-port=#{@api_port}#{opts}"
        opts = " --no-share#{opts}"

        cmd = "start \"vagrant-nfs4j-daemon\" #{cmd_base}#{opts}"
        ui.detail(I18n.t('vagrant_nfs4j.nfs4j_daemon.is_starting', cmd: cmd))

        pid = spawn(cmd)
        Process.detach(pid)

        i = 0
        check_start_time = Time.now
        until self.is_running(Time.now - check_start_time > 30, ui)
          sleep 1
          i += 1
        end

        ui.detail(I18n.t('vagrant_nfs4j.nfs4j_daemon.has_been_started'))

        true
      end

      def stop
        begin
          RestClient.post "http://127.0.0.1:#{@api_port}/stop", nil, self.headers()
        rescue
          raise StopFailed
        end
      end

      def headers()
        unless @api_bearer
          return {}
        end
        {:Authorization => "Bearer #{@api_bearer}"}
      end

      def attach(share)
        begin
          RestClient.post "http://127.0.0.1:#{@api_port}/attach", share.to_json, self.headers()
        rescue RestClient::Exception => e
          if e.http_code != 409
            raise AttachFailed
          else
            puts I18n.t('vagrant_nfs4j.nfs4j_daemon.errors.attach_failed', {:cause => Nfs4jDaemonErrors.get_message($!)})
          end
        rescue
          raise AttachFailed
        end
      end

      def detach(share)
        begin
          RestClient.post "http://127.0.0.1:#{@api_port}/detach", share.to_json, self.headers()
        rescue RestClient::Exception => e
          if e.http_code != 409
            raise DetachFailed
          else
            puts I18n.t('vagrant_nfs4j.nfs4j_daemon.errors.detach_failed', {:cause => Nfs4jDaemonErrors.get_message($!)})
          end
        rescue
          raise DetachFailed
        end
      end

      def status
        unless self.is_running
          return false
        end
        begin
          status = RestClient.get "http://127.0.0.1:#{@api_port}/status", self.headers()
          return JSON.parse(status)
        rescue
          raise StatusFailed
        end
      end
    end
  end
end