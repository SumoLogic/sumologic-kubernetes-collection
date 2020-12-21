require 'fluent/plugin/filter'

module Fluent
  module Plugin
    # fluentd filter plugin for appending Kubernetes metadata to events
    class EnhanceK8sMetadataFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter('enhance_k8s_metadata', self)

      require_relative '../../sumologic/kubernetes/cache_strategy.rb'
      require_relative '../../sumologic/kubernetes/service_monitor.rb'

      helpers :record_accessor
      helpers :thread
      helpers :timer
      include SumoLogic::Kubernetes::Connector
      include SumoLogic::Kubernetes::Reader
      include SumoLogic::Kubernetes::CacheStrategy
      include SumoLogic::Kubernetes::ServiceMonitor

      # parameters for read/write record
      config_param :in_namespace_path, :array, default: ['$.namespace']
      config_param :in_pod_path, :array, default: ['$.pod', '$.pod_name']
      config_param :data_type, :string, default: 'metrics'

      # parameters for connecting to k8s api server
      config_param :kubernetes_url, :string, default: nil
      config_param :client_cert, :string, default: nil
      config_param :client_key, :string, default: nil
      config_param :ca_file, :string, default: nil
      config_param :secret_dir, :string, default: '/var/run/secrets/kubernetes.io/serviceaccount'
      config_param :bearer_token_file, :string, default: nil
      config_param :verify_ssl, :bool, default: true
      # Need different clients to access different API groups/versions
      # https://github.com/abonas/kubeclient/issues/208
      config_param :core_api_versions, :array, default: ['v1']
      config_param :api_groups, :array, default: ["apps/v1", "extensions/v1beta1"]
      # if `ca_file` is for an intermediate CA, or otherwise we do not have the
      # root CA and want to trust the intermediate CA certs we do have, set this
      # to `true` - this corresponds to the openssl s_client -partial_chain flag
      # and X509_V_FLAG_PARTIAL_CHAIN
      config_param :ssl_partial_chain, :bool, default: false

      config_param :cache_size, :integer, default: 1000
      config_param :cache_ttl, :integer, default: 60 * 60 * 2
      config_param :cache_refresh, :integer, default: 60 * 60
      config_param :cache_refresh_variation, :integer, default: 60 * 15

      def configure(conf)
        super
        normalize_param
        log.info "Initializing kubernetes API clients"
        connect_kubernetes
        init_cache
        start_cache_timer
        @in_namespace_ac = @in_namespace_path.map { |path| record_accessor_create(path) }
        @in_pod_ac = @in_pod_path.map { |path| record_accessor_create(path) }
      end

      def start
        super
        start_service_monitor
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
          log.trace "Record doesn't have [#{@in_namespace_path}] field"
        elsif pod_name.nil?
          log.trace "Record doesn't have [#{@in_pod_path}] field"
        else
          if record.key? 'service'
            record['prometheus_service'] = record['service']
            record.delete('service')
          end
          metadata = get_pod_metadata(namespace_name, pod_name)
          service = @pods_to_services[pod_name] unless @pods_to_services.nil?
          metadata['service'] = {'service' => service.sort!.join('_')} if !(service.nil? || service.empty?)

          if @data_type == 'metrics' && (record['node'].nil? || record['node'] == "")
            record['node'] = metadata['node']
          end

          ['pod_labels', 'owners', 'service'].each do |metadata_type|
            attachment = metadata[metadata_type]
            if attachment.nil? || attachment.empty?
              log.trace "Cannot get #{metadata_type} for pod #{namespace_name}::#{pod_name}, skip."
            else
              case @data_type
              when 'logs'
                record['kubernetes'].merge! attachment if metadata_type != 'pod_labels'
              when 'metrics'
                record.merge! attachment
              else
                record.merge! attachment
              end
            end
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

        @cache_refresh_variation = 0 if @cache_refresh_variation < 0
        @cache_refresh_variation = 2 * @cache_refresh - 1 if @cache_refresh_variation >= @cache_refresh * 2

        log.info "cache_ttl: #{@cache_ttl}, cache_size: #{@cache_size}, cache_refresh: #{@cache_refresh}, cache_refresh_variation: #{@cache_refresh_variation}"
      end

      def start_cache_timer
        cache_refresh_with_variation = apply_variation(@cache_refresh, @cache_refresh_variation)
        log.info "Will refresh cache every #{format_time(cache_refresh_with_variation)}"
        timer_execute(:"cache_refresher", cache_refresh_with_variation) {
          entries = @cache.to_a
          log.info "Refreshing metadata for #{entries.count} entries"

          entries.each { |entry|
            begin
              log.debug "Refreshing metadata for key #{entry[0]}"
              split = entry[0].split("::")
              namespace_name = split[0]
              pod_name = split[1]
              metadata = fetch_pod_metadata(namespace_name, pod_name)
              @cache[entry[0]] = metadata unless metadata.empty?
            rescue => e
              log.error "Cannot refresh metadata for entry #{entry}: #{e}"
            end
          }
        }
      end

      def apply_variation(value, variation)
        return value if variation <= 0

        random_variation = rand(variation * 2 + 1) - variation
        value + random_variation
      end

      def format_time(seconds)
        Time.at(seconds).strftime("%Hh %Mm %Ss")
      end
    end
  end
end
