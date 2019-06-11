require 'fluent/plugin/filter'

module Fluent
  module Plugin
    # fluentd filter plugin for appending Kubernetes metadata to events
    class EnhanceK8sMetadataFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter('enhance_k8s_metadata', self)

      require_relative '../../sumologic/kubernetes/cache_strategy.rb'

      helpers :record_accessor
      include SumoLogic::Kubernetes::Connector
      include SumoLogic::Kubernetes::Reader
      include SumoLogic::Kubernetes::CacheStrategy

      # parameters for read/write record
      config_param :in_namespace_path, :array, default: ['$.namespace']
      config_param :in_pod_path, :array, default: ['$.pod', '$.pod_name']
      config_param :out_root, :string, default: 'kubernetes'

      # parameters for connecting to k8s api server
      config_param :kubernetes_url, :string, default: nil
      config_param :client_cert, :string, default: nil
      config_param :client_key, :string, default: nil
      config_param :ca_file, :string, default: nil
      config_param :secret_dir, :string, default: '/var/run/secrets/kubernetes.io/serviceaccount'
      config_param :bearer_token_file, :string, default: nil
      config_param :verify_ssl, :bool, default: true
      # if `ca_file` is for an intermediate CA, or otherwise we do not have the
      # root CA and want to trust the intermediate CA certs we do have, set this
      # to `true` - this corresponds to the openssl s_client -partial_chain flag
      # and X509_V_FLAG_PARTIAL_CHAIN
      config_param :ssl_partial_chain, :bool, default: false

      config_param :cache_size, :integer, default: 1000
      config_param :cache_ttl, :integer, default: 60 * 60

      def configure(conf)
        super
        normalize_param
        connect_kubernetes
        init_cache
        @in_namespace_ac = @in_namespace_path.map { |path| record_accessor_create(path) }
        @in_pod_ac = @in_pod_path.map { |path| record_accessor_create(path) }
      end

      def filter(tag, time, record)
        decorate_record(record)
        record
      end

      private

      def decorate_record(record)
        namespace_name = nil
        pod_name = nil
        @in_namespace_ac.each { |ac| namespace_name ||= ac.call(record) }
        @in_pod_ac.each { |ac| pod_name ||= ac.call(record) }
        if namespace_name.nil?
          log.debug "Record doesn't have [#{@in_namespace_path}] field"
        elsif pod_name.nil?
          log.debug "Record doesn't have [#{@in_pod_path}] field"
        else
          metadata = get_pod_metadata(namespace_name, pod_name)
          if metadata.empty?
            log.debug "Cannot get labels on pod #{namespace_name}::#{pod_name}, skip."
          else
            record[@out_root] = metadata
          end
        end
      end

      def normalize_param
        # Use Kubernetes default service account if running in a pod.
        if @kubernetes_url.nil?
          log.info 'Kubernetes URL is not set - inspecting environment'
          env_host = ENV['KUBERNETES_SERVICE_HOST']
          env_port = ENV['KUBERNETES_SERVICE_PORT']
          @kubernetes_url = "https://#{env_host}:#{env_port}" unless env_host.nil? || env_port.nil?
        end
        log.debug "Kubernetes URL: '#{@kubernetes_url}'"

        @ca_file = File.join(@secret_dir, K8_POD_CA_CERT) if @ca_file.nil?
        log.debug "ca_file: '#{@ca_file}', exist: #{File.exist?(@ca_file)}"

        @bearer_token_file = File.join(@secret_dir, K8_POD_TOKEN) if @bearer_token_file.nil?
        log.debug "bearer_token_file: '#{@bearer_token_file}', exist: #{File.exist?(@bearer_token_file)}"

        @cache_ttl = :none if @cache_ttl <= 0
        log.info "cache_ttl: #{cache_ttl}, cache_size: #{@cache_size}"

        @out_root = 'kubernetes' if @out_root.nil? || @out_root.empty?
        log.info "out_root: #{@out_root}"
      end
    end
  end
end
