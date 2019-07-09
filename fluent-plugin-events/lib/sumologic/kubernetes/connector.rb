module SumoLogic
    module Kubernetes
      # module for connecting to Kubernetes cluster
      module Connector
        require 'kubeclient'
  
        K8_POD_CA_CERT = 'ca.crt'.freeze
        K8_POD_TOKEN = 'token'.freeze
  
        def connect_kubernetes
          @client = Kubeclient::Client.new(
            @kubernetes_url, @api_version,
            ssl_options: ssl_options,
            auth_options: auth_options
          )
          @client.api_valid?
        rescue Exception => e
          log.error e
        end
        if !@client_cert.nil? && File.exist?(@client_cert)
          ssl_options[:client_cert] = OpenSSL::X509::Certificate.new(File.read(@client_cert))
        end
        if !@client_key.nil? && File.exist?(@client_key)
          ssl_options[:client_key] = OpenSSL::PKey::RSA.new(File.read(@client_key))
        end
        ssl_options[:cert_store] = ssl_store if @ssl_partial_chain
        log.debug "ssl_options: #{ssl_options}"
        ssl_options
      end

      def auth_options
        auth_options = {}
        if !@bearer_token_file.nil? && File.exist?(@bearer_token_file)
          auth_options[:bearer_token] = File.read(@bearer_token_file)
        end
        log.debug "auth_options: #{ssl_options}"
        auth_options
      end
    end
  end
end