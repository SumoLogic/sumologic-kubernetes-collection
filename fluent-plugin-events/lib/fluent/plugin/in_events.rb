require "fluent/plugin/input"
require 'kubeclient'

module Fluent
  module Plugin
    class EventsInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("events", self)

      require_relative '../../sumologic/kubernetes/connector.rb'

      helpers :thread

      include SumoLogic::Kubernetes::Connector
      
      # parameters for connecting to k8s api server
      config_param :kubernetes_url, :string, default: nil
      config_param :apiVersion, :string, default: 'v1'
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
      config_param :tag, :string, default: 'kubernetes.*'
      config_param :namespace, :string, default: nil
      config_param :label_selector, :string, default: nil
      config_param :field_selector, :string, default: nil
      config_param :configmap_update_interval_seconds, :integer, default: 10
      config_param :watch_interval_seconds, :integer, default: 300
      
      def configure(conf)
        super
        normalize_param
        connect_kubernetes
      end

      def start
        super
        initialize_resource_version
        start_monitor
      end
  
      def close
        log.info "closing"
        update_config_map
        log.info "updated configmap"
        @watcher.each &:finish
        super
      end

      def start_monitor
        last_http_start = Time.now.to_i
        log.info "last_http_start initialized to #{last_http_start}"

        @resource = ::Kubeclient::Resource.new
        @resource.metadata = {
          name: "fluentd-config-resource-version",
          namespace: "sumologic"
        }
        
        while true do
          # Periodically restart watcher connection by checking if enough time has passed since 
          # last time watcher thread was recreated or if the watcher thread has died.
          now = Time.now.to_i
          log.info "now is #{now}"
          log.info "is there no thread with same id? #{Thread.list.select {|thread| thread.object_id == @watcher_id}.count < 1}"
          log.info "is there no thread with same id and running? #{Thread.list.select {|thread| thread.object_id == @watcher_id && thread.status == "run"}.count < 1}"
          log.info "thread with id #{@watcher_id} has status #{Thread.list.select {|thread| thread.object_id == @watcher_id}.first.status}"
          
          if now - last_http_start >= @watch_interval_seconds ||
            Thread.list.select {
              |thread| thread.object_id == @watcher_id && thread.status == "run"
            }.count < 1
            
            log.info "time to recreate watcher thread"
            pull_resource_version
            
            log.info "watch_stream has type #{@watch_stream.class}"
            @watch_stream.each &:finish if @watch_stream
            
            start_watcher_thread

            last_http_start = now
            log.info "last_http_start updated to #{last_http_start}"

          end

          sleep(@configmap_update_interval_seconds)
          log.info
          update_config_map
        end
      end

      def initialize_resource_version
        # get or create the config map
        begin
          @client.public_send("get_config_map", "fluentd-config-resource-version", "sumologic").tap do |resource|
            log.info "Get config maps: #{resource}"
            version = resource.data['resource-version']
            @resource_version = version.to_i + 1 if version
          end
        rescue Kubeclient::ResourceNotFoundError
          create_config_maps
        end
      end

      def create_config_maps
        @resource_version = 0
        resource = ::Kubeclient::Resource.new
        resource.metadata = {
          name: "fluentd-config-resource-version",
          namespace: "sumologic"
        }
        resource.data = { "resource-version": "#{@resource_version}" }
        @client.public_send("create_config_map", resource).tap do |maps|
          log.info "Created config maps: #{maps}"
        end
      end

      def pull_resource_version
        params = Hash.new
        params[:as] = :raw
        response = @client.public_send "get_events", params
        result = JSON.parse(response)

        resource_version = result.fetch('resourceVersion') do
          result.fetch('metadata', {})['resourceVersion']
        end

        log.info "resource version is #{resource_version}"
        @resource_version = resource_version
      end
  
      def start_watcher_thread
        log.info "Starting watcher thread #{Thread.current.object_id}"
        params = Hash.new
        params[:as] = :raw
        params[:resource_version] = @resource_version
        params[:field_selector] = @field_selector
        params[:label_selector] = @label_selector
        params[:namespace] = @namespace
        params[:timeout_seconds] = @watch_interval_seconds + 60

        @watcher = @client.public_send("watch_events", params).tap do |watcher|
          thread_create(:"watch_events") do
            @watcher_id = Thread.current.object_id
            log.info "New thread to watch events #{@watcher_id} with watcher type #{watcher.class}"
            log.info "!!!!!!! #{Thread.list.select {|thread| thread.object_id == @watcher_id}.count}"
            @watch_stream = watcher
           
            watcher.each do |entity|
              # log.debug "Before parse #{entity.class} and entity #{entity}"
              begin
                entity = JSON.parse(entity)
                log.debug "Got new event"
                router.emit tag, Fluent::Engine.now, entity
                rv = entity['object']['metadata']['resourceVersion']
              rescue => e
                log.error "Got exception #{e} parsing entity #{entity}. Skipping."
              end

              if (!rv)
                log.error "Resource version #{rv} expired"
                @resource_version = current snapshot (pull first)
                sleep(5)
                start_watcher_thread
                break
              end
            end
          end

          log.info "Watcher has type #{@watcher.class}"
        end
      end

      def start_configmap_flush_thread
        thread_create(:"update_configmap") do
          
          while true do
            sleep(@configmap_update_interval_seconds)
            update_config_map
          end
        end
      end

      def update_config_map
        pull_resource_version
        @resource.data = { "resource-version": "#{@resource_version}"}

        # update the config map
        @client.public_send("update_config_map", @resource).tap do |maps|
          log.debug "Updated config maps: #{maps}"
        end
      end

      def normalize_param
        # Use Kubernetes default service account if running in a pod.
        if @kubernetes_url.nil?
          log.debug 'Kubernetes URL is not set - inspecting environment'
          env_host = ENV['KUBERNETES_SERVICE_HOST']
          env_port = ENV['KUBERNETES_SERVICE_PORT']
          @kubernetes_url = "https://#{env_host}:#{env_port}/api" unless env_host.nil? || env_port.nil?
        end
        log.info "Kubernetes URL: '#{@kubernetes_url}'"

        @ca_file = File.join(@secret_dir, K8_POD_CA_CERT) if @ca_file.nil?
        log.info "ca_file: '#{@ca_file}', exist: #{File.exist?(@ca_file)}"

        @bearer_token_file = File.join(@secret_dir, K8_POD_TOKEN) if @bearer_token_file.nil?
        log.info "bearer_token_file: '#{@bearer_token_file}', exist: #{File.exist?(@bearer_token_file)}"
      end
    end
  end
end
