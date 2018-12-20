require 'vagrant'
require_relative '../nfs4j_daemon/wrapper'
require 'open3'

module VagrantNfs4j
  module Config
    class Nfs4j < Vagrant.plugin('2', :config)
      attr_accessor :shares_config
      attr_accessor :host_ip
      attr_accessor :api_port
      attr_accessor :api_bearer
      attr_accessor :setup_firewall
      attr_accessor :daemon_start
      attr_accessor :daemon_exe
      attr_accessor :daemon_jar
      attr_accessor :daemon_cmd
      attr_accessor :daemon_opts
      attr_accessor :java_home
      attr_accessor :java_opts

      def initialize
        @shares_config = UNSET_VALUE
        @host_ip = UNSET_VALUE
        @api_port = UNSET_VALUE
        @api_bearer = UNSET_VALUE
        @setup_firewall = UNSET_VALUE
        @daemon_start = UNSET_VALUE
        @daemon_exe = UNSET_VALUE
        @daemon_jar = UNSET_VALUE
        @daemon_cmd = UNSET_VALUE
        @daemon_opts = UNSET_VALUE
        @java_home = UNSET_VALUE
        @java_opts = UNSET_VALUE
      end

      def validate(machine)
        errors = []

        config = machine.config.nfs4j

        errors << 'nfs4j.shares_config cannot be nil.' if config.shares_config.nil?
        errors << 'nfs4j.host_ip cannot be nil.' if config.host_ip.nil?
        errors << 'nfs4j.api_port cannot be nil.' if config.api_port.nil?

        java_required = false
        if config.daemon_start
          begin
            stdout, stderr, status = Open3.capture3("#{config.daemon_cmd} -h")
            if status.to_i != 0
              java_required = true
              errors << "nfs4j-daemon cannot be executed (#{config.daemon_cmd}) [#{status}]. check nfs4j.daemon_* and nfs4j.java_* options."
            elsif not stdout.include?('[<shares>...]')
              java_required = true
              errors << "nfs4j-daemon cannot be executed (#{config.daemon_cmd}) [doesn't looks like nfs4j-daemon]. check nfs4j.daemon_* and nfs4j.java_* options."
            end
          rescue StandardError => err
            java_required = true
            errors << "nfs4j-daemon cannot be executed (#{config.daemon_cmd}): #{err.message}. check nfs4j.daemon_* and nfs4j.java_* options."
          end
        end

        errors << "nfs4j-daemon requires Java >= 8. Make sure you actually have a JRE/JDK installed and JAVA_HOME environment variable or nfs4j.java_home option is set to JRE/JDK installation directory." if java_required

        {"nsf4j" => errors}
      end

      def finalize!
        @shares_config = {} if @shares_config == UNSET_VALUE
        @host_ip = "" if @host_ip == UNSET_VALUE
        @api_port = 9732 if @api_port == UNSET_VALUE
        @api_bearer = nil if @api_bearer == UNSET_VALUE
        @setup_firewall = true if @setup_firewall == UNSET_VALUE
        @daemon_start = true if @daemon_start == UNSET_VALUE
        @daemon_exe = true if @daemon_exe == UNSET_VALUE
        @daemon_jar = false if @daemon_jar == UNSET_VALUE
        @daemon_cmd = nil if @daemon_cmd == UNSET_VALUE
        @daemon_opts = nil if @daemon_opts == UNSET_VALUE
        @java_home = ENV['JAVA_HOME'] if @java_home == UNSET_VALUE
        @java_opts = ENV['JAVA_OPTS'] if @java_opts == UNSET_VALUE

        ENV['JAVA_HOME'] = @java_home if @java_home
        ENV['JAVA_OPTS'] = @java_opts if @java_opts

        if @daemon_jar
          @daemon_exe = false
        end

        if @daemon_exe
          @daemon_jar = false
        end

        if @daemon_cmd
          @daemon_exe = false
          @daemon_jar = false
        else
          @daemon_cmd = VagrantNfs4j::Nfs4jDaemon::Wrapper.new(
              config.api_port,
              config.api_bearer
          ).get_cmd_base(@daemon_exe, @daemon_jar, @java_home, @java_opts)
        end
      end
    end
  end
end
