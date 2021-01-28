module SumoLogic
  module Kubernetes
    # module for connecting to Kubernetes cluster
    module Connector
      require 'kubeclient'

      K8_POD_CA_CERT = 'ca.crt'.freeze
      K8_POD_TOKEN = 'token'.freeze

      def connect_kubernetes
        @clients = api_clients
      end

      CORE_API_VERSION = 'v1'

      def api_clients
        versions = @api_version != CORE_API_VERSION ? [@api_version, CORE_API_VERSION] : [CORE_API_VERSION]
        ret = {}

        versions.each do |ver|
          elems = ver.split("/")
          if elems.length < 2
            # only a version: create a 'non-group' api
            ret[ver] = create_client('api', ver)
          else
            # there are more elements, each one should have
            # a base as key e.g. 'extensions' and a version as value e.g. 'v1beta1'
            base = elems[0].to_s
            version = elems[1]
            ret[ base + "/" + version ] = create_client('apis/' + base, version)
          end
        end
        ret
      end

      def create_client(base, ver)
        retries = 0
        url = "#{@kubernetes_url}/#{base}"
        begin
          client = nil
          unless client
            log.info "create client with URL: #{url} and apiVersion: #{ver}"
            client = Kubeclient::Client.new(
              url, ver,
              ssl_options: ssl_options,
              auth_options: auth_options
            )
            client.faraday_client.adapter(:net_http_persistent)
            client.api_valid?
          end
          client
        rescue StandardError => e
          ## retry up to ~4 minutes
          if (retries += 1) <= 7
            log.error "Error creating client (#{e}), retrying in #{2 ** retries} second(s)..."
            sleep(2 ** retries)
            retry
          else
            raise
          end
        end
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
        log.debug "auth_options: #{ssl_options}"
        auth_options
      end
    end
  end
end
