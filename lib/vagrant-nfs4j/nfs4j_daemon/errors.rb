require 'rest-client'
require 'json'

module VagrantNfs4j
  module Nfs4jDaemon
    class Nfs4jDaemonErrors < Vagrant::Errors::VagrantError
      def self.get_message(cause)
        message = cause.message
        if cause.is_a?(RestClient::Exception)
          begin
            if cause.http_headers[:content_type] == "application/json"
              error = JSON.parse(cause.http_body)
              if error['error']
                message += " [#{error['message']}]"
              end
            end
          rescue
            # Do nothing
          end
        end
        message
      end
      
      def initialize(*args)
        key = args.shift if args.first.is_a?(Symbol)
        message = args.shift if args.first.is_a?(Hash)
        message ||= {}

        cause = $!
        if (cause)
          message[:cause] = cause.message
          if cause.is_a?(RestClient::Exception)
            begin
              if cause.http_headers[:content_type] == "application/json"
                error = JSON.parse(cause.http_body)
                if error['error']
                  message[:cause] += " [#{error['message']}]"
                  message = extra_data.merge(error)
                end
              end
            rescue
              # Do nothing
            end
          end
        end

        args.push(key) if key
        args.push(message)

        super(*args)
      end

      error_namespace('vagrant_nfs4j.nfs4j_daemon.errors')
    end

    class Nfs4jUnavailable < Nfs4jDaemonErrors
      error_key(:unavailable)
    end

    class TimeoutError < Nfs4jDaemonErrors
      error_key(:timeout_error)
    end

    class StartFailed < Nfs4jDaemonErrors
      error_key(:start_failed)
    end

    class StopFailed < Nfs4jDaemonErrors
      error_key(:stop_failed)
    end

    class AttachFailed < Nfs4jDaemonErrors
      error_key(:attach_failed)
    end

    class DetachFailed < Nfs4jDaemonErrors
      error_key(:detach_failed)
    end
    
    class StatusFailed < Nfs4jDaemonErrors
      error_key(:status_failed)
    end
  end
end 