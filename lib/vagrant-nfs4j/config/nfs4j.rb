require 'vagrant'

module VagrantNfs4j
  module Config
    class Nfs4j < Vagrant.plugin('2', :config)
      attr_accessor :config
      attr_accessor :shares_config
      attr_accessor :host_ip
      attr_accessor :api_port
      attr_accessor :setup_firewall
      attr_accessor :daemon_start
      attr_accessor :daemon_exe
      attr_accessor :daemon_jar
      attr_accessor :daemon_opts
      attr_accessor :java_home
      attr_accessor :java_opts

      def initialize
        @config = UNSET_VALUE
        @shares_config = UNSET_VALUE
        @host_ip = UNSET_VALUE
        @api_port = UNSET_VALUE
        @setup_firewall = UNSET_VALUE
        @daemon_start = UNSET_VALUE
        @daemon_exe = UNSET_VALUE
        @daemon_jar = UNSET_VALUE
        @daemon_opts = UNSET_VALUE
        @java_home = UNSET_VALUE
        @java_opts = UNSET_VALUE
      end

      def validate(machine)
        errors = []
        errors << 'nfs4j.config cannot be nil.' if machine.config.nfs4j.config.nil?
        errors << 'nfs4j.shares_config cannot be nil.' if machine.config.nfs4j.shares_config.nil?
        errors << 'nfs4j.host_ip cannot be nil.' if machine.config.nfs4j.host_ip.nil?
        errors << 'nfs4j.api_port cannot be nil.' if machine.config.nfs4j.api_port.nil?

        {"nsf4j" => errors}
      end

      def finalize!
        @config = {} if @config == UNSET_VALUE
        @shares_config = {} if @shares_config == UNSET_VALUE
        @host_ip = "" if @host_ip == UNSET_VALUE
        @api_port = 9732 if @api_port == UNSET_VALUE
        @setup_firewall = true if @setup_firewall == UNSET_VALUE
        @daemon_start = true if @daemon_start == UNSET_VALUE
        @daemon_exe = true if @daemon_exe == UNSET_VALUE
        @daemon_jar = true if @daemon_jar == UNSET_VALUE
        @daemon_opts = nil if @daemon_opts == UNSET_VALUE
        @java_home = ENV['JAVA_HOME'] if @java_home == UNSET_VALUE
        @java_opts = ENV['JAVA_OPTS'] if @java_opts == UNSET_VALUE
      end
    end
  end
end
