require "fluent/plugin/input"
require 'kubeclient'

module Fluent
  module Plugin
    class EventsInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("events", self)

      require_relative '../../sumologic/kubernetes/connector.rb'

      helpers :thread, :timer

      include SumoLogic::Kubernetes::Connector
      
      # parameters for connecting to k8s api server
      config_param :kubernetes_url, :string, default: nil
      # api_version is used to create:
      # * a group api e.g. "events.k8s.io/v1beta1" additionally to 'v1' api
      # * a regular api e.g. 'v1', if a different version than 'v1' is specified
      #    then it will be created additionally to 'v1'
      config_param :api_version, :string, default: 'v1'
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
      
      # parameters for events collection
      config_param :resource_name, :string, default: "events"
      config_param :tag, :string, default: 'kubernetes.*'
      config_param :namespace, :string, default: nil
      config_param :label_selector, :string, default: nil
      config_param :field_selector, :string, default: nil
      config_param :type_selector, :array, default: ["ADDED", "MODIFIED"], value_type: :string
      config_param :configmap_update_interval_seconds, :integer, default: 10
      config_param :watch_interval_seconds, :integer, default: 300
      config_param :deploy_namespace, :string, default: "sumologic"
      
      def configure(conf)
        super

        @valid_types = ["ADDED", "MODIFIED", "DELETED"]
        raise Fluent::ConfigError, "type_selector needs to be an array with maximum #{@valid_types.length} elements: #{@valid_types.join(", ")}." \
          if @type_selector.length > @valid_types.length || !@type_selector.any? || !@type_selector.all? {|type| @valid_types.any? {|valid| valid.casecmp?(type)}}

        normalize_param
        log.info "Initializing kubernetes API clients"
        connect_kubernetes
      end

      def start
        log.info "Starting events collection for #{@resource_name}"
        
        super
        initialize_resource_version
        
        @last_recreated = Time.now.to_i
        log.debug "last_recreated initialized to #{@last_recreated}"

        timer_execute(:"#{@resource_name}_monitor", @configmap_update_interval_seconds, &method(:start_monitor))
      end
  
      def stop
        log.debug "Clean up before stopping completely"
        patch_config_map
        @watch_stream.finish if @watch_stream
        super
      end

      def start_monitor
        now = Time.now.to_i
        watcher_exists = Thread.list.select {|thread| thread.object_id == @watcher_id && thread.alive?}.count > 0
        if now - @last_recreated >= @watch_interval_seconds || !watcher_exists
          
          log.debug "Recreating watcher thread. Use resource version from latest snapshot if watcher is running"
          pull_resource_version if watcher_exists
          @watch_stream.finish if @watch_stream

          start_watcher_thread
          @last_recreated = now
          log.debug "last_recreated updated to #{@last_recreated}"
        end

        patch_config_map
      end
  
      def start_watcher_thread
        log.debug "Starting watcher thread"
        params = Hash.new
        params[:as] = :raw
        params[:resource_version] = @resource_version
        params[:field_selector] = @field_selector
        params[:label_selector] = @label_selector
        params[:namespace] = @namespace
        params[:timeout_seconds] = @watch_interval_seconds + 60

        @watcher = @clients[@api_version].public_send("watch_#{resource_name}", params).tap do |watcher|
          thread_create(:"watch_#{resource_name}") do
            @watch_stream = watcher
            @watcher_id = Thread.current.object_id
            log.debug "New thread to watch #{resource_name} #{@watcher_id} from resource version #{params[:resource_version]}"

            watcher.each do |entity|
              begin
                entity = JSON.parse(entity)
                router.emit tag, Fluent::Engine.now, entity if @type_selector.any? {|type| type.casecmp?(entity['type'])}
                rv = entity['object']['metadata']['resourceVersion']
              rescue => e
                log.error "Got exception #{e} parsing entity #{entity}. Skipping."
              end

              if (!rv)
                log.warn "Resource version #{rv} expired, waiting for stream to be recreated with more recent version."
                break
              end
            end

            log.debug "Closing watch stream"
          end
        end
      rescue => e
        log.error "Got exception #{e} watching for resource #{resource_name}. Skipping."
      end

      def create_config_map
        @configmap.data = { "resource-version-#{resource_name}": "#{@resource_version}" }
        @clients['v1'].public_send("create_config_map", @configmap).tap do |map|
          log.debug "Created config map: #{map}"
        end
      rescue => e
        log.error "Got exception #{e} creating config map. Skipping."
      end

      def patch_config_map
        pull_resource_version
        @clients['v1'].public_send("patch_config_map", "fluentd-config-resource-version", {data: { "resource-version-#{resource_name}": "#{@resource_version}"}}, @deploy_namespace).tap do |map|
          log.debug "Patched config map for #{@resource_name}: #{map}"
        end
      rescue => e
        log.error "Got exception #{e} patching config map. Skipping."
      end

      def initialize_resource_version
        @resource_version = 0
        @configmap = ::Kubeclient::Resource.new
        @configmap.metadata = {
          name: "fluentd-config-resource-version",
          namespace: @deploy_namespace
        }

        # get or create the config map
        begin
          @clients['v1'].public_send("get_config_map", "fluentd-config-resource-version", @deploy_namespace).tap do |resource|
            log.debug "Got config map: #{resource}"
            version = resource.data["resource-version-#{resource_name}"]
            @resource_version = version.to_i if version
          end
        rescue Kubeclient::ResourceNotFoundError
          create_config_map
        rescue => e
          log.error "Got exception #{e} getting config map. Skipping."
        end
      end

      def pull_resource_version
        params = Hash.new
        params[:as] = :raw

        response = @clients[@api_version].public_send("get_#{resource_name}", params)
        result = JSON.parse(response)

        resource_version = result.fetch('resourceVersion') do
          result.fetch('metadata', {})['resourceVersion']
        end

        @resource_version = resource_version
      rescue => e
        log.error "Got exception #{e} pulling resource version #{resource_version} for resource #{resource_name}. Skipping."
      end

      def normalize_param
        # Use Kubernetes default service account if running in a pod.
        if @kubernetes_url.nil?
          log.debug 'Kubernetes URL is not set - inspecting environment'
          env_host = ENV['KUBERNETES_SERVICE_HOST']
          env_port = ENV['KUBERNETES_SERVICE_PORT']
          @kubernetes_url = "https://#{env_host}:#{env_port}" unless env_host.nil? || env_port.nil?
        end
        log.debug "Kubernetes URL: '#{@kubernetes_url}'"

        @ca_file = File.join(@secret_dir, K8_POD_CA_CERT) if @ca_file.nil?
        log.debug "ca_file: '#{@ca_file}', exist: #{File.exist?(@ca_file)}"

        @bearer_token_file = File.join(@secret_dir, K8_POD_TOKEN) if @bearer_token_file.nil?
        log.debug "bearer_token_file: '#{@bearer_token_file}', exist: #{File.exist?(@bearer_token_file)}"
      end
    end
  end
end
