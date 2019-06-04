module SumoLogic
    module Kubernetes
      # module for connecting to Kubernetes cluster
      module Connector
        require 'kubeclient'
  
        K8_POD_CA_CERT = 'ca.crt'.freeze
        K8_POD_TOKEN = 'token'.freeze
  
        def connect_kubernetes
          @client = Kubeclient::Client.new(
            @kubernetes_url, @apiVersion,
            ssl_options: ssl_options,
            auth_options: auth_options
          )
          @client.api_valid?
        rescue Exception => e
          log.error e
        end
  
        def ssl_store
          require 'openssl'
          ssl_store = OpenSSL::X509::Store.new
          ssl_store.set_default_paths
          # if version of ruby does not define OpenSSL::X509::V_FLAG_PARTIAL_CHAIN
          flagval = 0x80000
          flagval = OpenSSL::X509::V_FLAG_PARTIAL_CHAIN if defined? OpenSSL::X509::V_FLAG_PARTIAL_CHAIN
          ssl_store.flags = OpenSSL::X509::V_FLAG_CRL_CHECK_ALL | flagval
          ssl_store
        end
  
        def ssl_options
          ssl_options = {}
          ssl_options[:verify_ssl] = @verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
          if !@ca_file.nil? && File.exist?(@ca_file)
            ssl_options[:ca_file] = @ca_file
          end
          if !@client_cert.nil? && File.exist?(@client_cert)
            ssl_options[:client_cert] = OpenSSL::X509::Certificate.new(File.read(@client_cert))
          end
          if !@client_key.nil? && File.exist?(@client_key)
            ssl_options[:client_key] = OpenSSL::PKey::RSA.new(File.read(@client_key))
          end
          ssl_options[:cert_store] = ssl_store if @ssl_partial_chain
          log.info "ssl_options: #{ssl_options}"
          ssl_options
        end
  
        def auth_options
          auth_options = {}
          if !@bearer_token_file.nil? && File.exist?(@bearer_token_file)
            auth_options[:bearer_token] = File.read(@bearer_token_file)
          end
          log.info "auth_options: #{ssl_options}"
          auth_options
        end
      end
    end
  end