require "fluent/plugin/input"
require 'kubeclient'

module Fluent
  module Plugin
    class EventsInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("events", self)

      helpers :thread

      config_param :kubernetes_url, :string, default: nil
      config_param :api_version, :string, default: 'v1'
      config_param :client_cert, :string, default: nil
      config_param :client_key, :string, default: nil
      config_param :ca_file, :string, default: nil
      config_param :insecure_ssl, :bool, default: false
      config_param :bearer_token_file, :string, default: nil
      config_param :secret_dir, :string, default: '/var/run/secrets/kubernetes.io/serviceaccount'
      config_param :tag, :string, default: 'kubernetes.*'
      config_param :namespace, :string, default: nil
      config_param :label_selector, :string, default: nil
      config_param :field_selector, :string, default: nil
      
      def configure(conf)
        super
        initialize_client
      end

      def start
        super
        initialize_resource_version
        start_watcher_thread
        start_configmap_flush_thread
      end
  
      def close
        @watcher.each &:finish
        super
      end

      def initialize_client
        log.trace { "Initializing client" }
        # mostly borrowed from Fluentd Kubernetes Metadata Filter Plugin
        if @kubernetes_url.nil?
          # Use Kubernetes default service account if we're in a pod.
          env_host = ENV['KUBERNETES_SERVICE_HOST']
          env_port = ENV['KUBERNETES_SERVICE_PORT']
          if env_host && env_port
            @kubernetes_url = "https://#{env_host}:#{env_port}/#{@api_version == 'v1' ? 'api' : 'apis'}"
          end
        end
  
        raise Fluent::ConfigError, 'kubernetes url is not set' unless @kubernetes_url
  
        # Use SSL certificate and bearer token from Kubernetes service account.
        if Dir.exist?(@secret_dir)
          secret_ca_file = File.join(@secret_dir, 'ca.crt')
          secret_token_file = File.join(@secret_dir, 'token')
  
          if @ca_file.nil? && File.exist?(secret_ca_file)
            @ca_file = secret_ca_file
          end
  
          if @bearer_token_file.nil? && File.exist?(secret_token_file)
            @bearer_token_file = secret_token_file
          end
        end
  
        ssl_options = {
          client_cert: @client_cert && OpenSSL::X509::Certificate.new(File.read(@client_cert)),
          client_key: @client_key && OpenSSL::PKey::RSA.new(File.read(@client_key)),
          ca_file: @ca_file,
          verify_ssl: @insecure_ssl ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
        }
  
        auth_options = {}
        auth_options[:bearer_token] = File.read(@bearer_token_file) if @bearer_token_file
  
        @client = Kubeclient::Client.new(
          @kubernetes_url, @api_version,
          ssl_options: ssl_options,
          auth_options: auth_options
        )
  
        begin
            @client.api_valid?
        rescue KubeException => kube_error
          raise Fluent::ConfigError, "Invalid Kubernetes API #{@api_version} endpoint #{@kubernetes_url}: #{kube_error.message}"
          end
      end

      def initialize_resource_version
        # get or create the config map
        begin
          @client.public_send("get_config_map", "fluentd-config-resource-version", "sumologic").tap do |resource|
            log.trace {"Get config maps: #{resource}"}
            version = resource.data['resource-version']
            log.trace { "Get version from config map: #{version}"}
            @resource_version = version if version
          end
        rescue Kubeclient::ResourceNotFoundError
          create_config_maps
        end
      end

      def create_config_maps
        @resource_version = "0"
        resource = ::Kubeclient::Resource.new
        resource.metadata = {
          name: "fluentd-config-resource-version",
          namespace: "sumologic"
        }
        resource.data = { "resource-version": "#{@resource_version}" }
        @client.public_send("create_config_map", resource).tap do |maps|
          log.trace {"Created config maps: #{maps}"}
        end
      end
  
      def start_watcher_thread
        params = Hash.new
        params[:as] = :raw
        params[:resource_version] = @resource_version
        params[:field_selector] = @field_selector
        params[:label_selector] = @label_selector
        params[:namespace] = @namespace

        @watcher = @client.public_send("watch_events", params).tap do |watcher|
          thread_create(:"watch_events") do
            watcher.each do |entity|
              log.trace { "Received new object from watching events" }
              entity = JSON.parse(entity)
              router.emit tag, Fluent::Engine.now, entity
              @resource_version = entity['object']['metadata']['resourceVersion']
  
              if (!@resource_version)
                @resource_version = 0
                sleep(5)
                start_watcher_thread
                break
              end
  
              log.trace { "resource version: #{entity['object']['metadata']['resourceVersion']}"}
            end
          end
        end
      end

      def start_configmap_flush_thread
        thread_create(:"update_configmap") do
          resource = ::Kubeclient::Resource.new
          resource.metadata = {
            name: "fluentd-config-resource-version",
            namespace: "sumologic"
          }
          while true do
            sleep(10)
            resource.data = { "resource-version": "#{@resource_version}"}

            # update the config map
            @client.public_send("update_config_map", resource).tap do |maps|
              log.trace {"Updated config maps: #{maps}"}
            end
          end
        end
      end 
    end
  end
end
