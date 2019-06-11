module SumoLogic
  module Kubernetes
    # module for connecting to Kubernetes cluster
    module Connector
      require 'kubeclient'

      K8_POD_CA_CERT = 'ca.crt'.freeze
      K8_POD_TOKEN = 'token'.freeze

      # Need different clients to access deifferent API groups/versions
      # https://github.com/abonas/kubeclient/issues/208
      CORE_API_VERSIONS = ['v1'].freeze
      API_GROUPS = ['apps/v1', 'extensions/v1beta1'].freeze

      def connect_kubernetes
        @clients = core_clients.merge(group_clients)
      end

      def core_clients
        CORE_API_VERSIONS.map do |ver|
          [ver, create_client('api', ver)]
        end.to_h
      end

      def group_clients
        API_GROUPS.map do |ver|
          [ver, create_client('apis', ver)]
        end.to_h
      end

      def create_client(base, ver)
        url = "#{@kubernetes_url}/#{base}/#{ver}"
        log.info "create client with URL: #{url}"
        client = Kubeclient::Client.new(
          url,
          '',
          ssl_options: ssl_options,
          auth_options: auth_options,
          as: :parsed
        )
        client.api_valid?
        client
      rescue StandardError => e
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
        log.debug "ssl_options: #{ssl_options}"
        ssl_options
      end

      def auth_options
        auth_options = {}
        if !@bearer_token_file.nil? && File.exist?(@bearer_token_file)
          auth_options[:bearer_token] = File.read(@bearer_token_file)
        end
        log.debug "auth_options: #{auth_options}"
        auth_options
      end
    end
  end
end
