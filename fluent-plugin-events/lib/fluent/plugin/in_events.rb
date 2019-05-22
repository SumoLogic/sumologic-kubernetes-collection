require "fluent/plugin/input"
require 'kubeclient'

module Fluent
  module Plugin
    class EventsInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("events", self)

      helpers :storage, :thread

      desc 'The tag of the event.'
      config_param :tag, :string, default: 'kubernetes.*'
  
      desc 'URL of the kubernetes API.'
      config_param :kubernetes_url, :string, default: nil
  
      desc 'Kubernetes API version.'
      config_param :api_version, :string, default: 'v1'
  
      desc 'Path to the certificate file for this client.'
      config_param :client_cert, :string, default: nil
  
      desc 'Path to the private key file for this client.'
      config_param :client_key, :string, default: nil
  
      desc 'Path to the CA file.'
      config_param :ca_file, :string, default: nil
  
      desc "If `insecure_ssl` is set to `true`, it won't verify apiserver's certificate."
      config_param :insecure_ssl, :bool, default: false
  
      desc 'Path to the file contains the API token. By default it reads from the file "token" in the `secret_dir`.'
      config_param :bearer_token_file, :string, default: nil
  
      desc "Path of the location where pod's service account's credentials are stored."
      config_param :secret_dir, :string, default: '/var/run/secrets/kubernetes.io/serviceaccount'

      desc 'Define a resource to watch.'
      config_section :watch, required: false, init: false, multi: true, param_name: :watch_objects do
        desc 'The name of the resource, e.g. "events".'
        config_param :resource_name, :string
  
        desc 'The namespace of the resource, it watches all namespaces if not set.'
        config_param :namespace, :string, default: nil
  
        desc 'The name of the entity to watch, use this to watch only one entity.'
        config_param :entity_name, :string, default: nil
  
        desc 'A selector to restrict the list of returned objects by labels.'
        config_param :label_selector, :string, default: nil
  
        desc 'A selector to restrict the list of returned objects by fields.'
        config_param :field_selector, :string, default: nil
      end
  
      config_section :storage do
        # use memory by default
        config_set_default :usage, 'checkpoints'
        config_set_default :@type, 'local'
        config_set_default :persistent, false
      end
      
      def configure(conf)
        super
  
        log.trace { "Configure" }
        raise Fluent::ConfigError, 'At least <watch> is required, but found none.' if @watch_objects.empty?
  
        @storage = storage_create usage: 'checkpoints'
  
        parse_tag
        initialize_client
      end

      def parse_tag
        @tag_prefix, @tag_suffix = @tag.split('*') if @tag.include?('*')
      end

      def generate_tag(item_name)
        return @tag unless @tag_prefix
  
        [@tag_prefix, item_name, @tag_suffix].join
      end

      def start
        super
        start_watchers
        create_configmap_flush_thread
        # create_config_maps
      end
  
      def close
        @watchers.each &:finish if @watchers
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

      def create_config_maps
        resource = ::Kubeclient::Resource.new
        resource.metadata = {
          name: "fluentd-config-resource-version",
          namespace: "sumologic",
          labels: { "k8s-app": "fluentd-sumologic-events" }
        }
        resource.data = { values: "some-strings" }
        @client.public_send("create_config_map", resource).tap do |maps|
          log.trace {"Created config maps: #{maps}"}
        end

        # update the config map
        resource.data = { values: "another-strings"}
        @client.public_send("update_config_map", resource).tap do |maps|
          log.trace {"Updated config maps: #{maps}"}
        end

        # get the config map
        @client.public_send("get_config_map", "fluentd-config-resource-version", "sumologic").tap do |maps|
          log.trace {"Get config maps: #{maps}"}
        end
      end
  
      def start_watchers
        log.trace { "Starting watchers" }
        @watchers = @watch_objects.map do |o|
          o = o.to_h.dup
          o[:as] = :raw
          resource_name = o.delete(:resource_name)
          # version = @storage.get(resource_name)
          # get the config map
          @client.public_send("get_config_map", "fluentd-config-resource-version", "sumologic").tap do |resource|
            log.trace {"Get config maps: #{resource}"}
            version = resource.data['resource-version']
            log.trace { "Get version from config map: #{version}"}
            o[:resource_version] = version if version
          end
          log.trace { "Get o version: #{o[:resource_version]}"}
          @resource_version = o[:resource_version] if o[:resource_version] else "0"
          @client.public_send("watch_#{resource_name}", o).tap do |watcher|
           create_watcher_thread resource_name, watcher
          end
        end
      end
  
      def create_watcher_thread(object_name, watcher)
        thread_create(:"watch_#{object_name}") do
          tag = generate_tag "#{object_name}.watch"
          watcher.each do |entity|
            log.trace { "Received new object from watching #{object_name}" }
            entity = JSON.parse(entity)
            router.emit tag, Fluent::Engine.now, entity
            @resource_version = entity['object']['metadata']['resourceVersion']
            log.trace { "resource version: #{entity['object']['metadata']['resourceVersion']}"}
          end
        end
      end

      def create_configmap_flush_thread
        thread_create(:"update_configmap") do
          resource = ::Kubeclient::Resource.new
          resource.metadata = {
            name: "fluentd-config-resource-version",
            namespace: "sumologic",
            labels: { "k8s-app": "fluentd-sumologic-events" }
          }
          while true do
            log.trace { "resource version #{@resource_version}"}
            resource.data = { "resource-version": "#{@resource_version}"}

            # update the config map
            @client.public_send("update_config_map", resource).tap do |maps|
              log.trace {"Updated config maps: #{maps}"}
            end
            sleep(5)
            log.trace {"Sleep done."}
          end
        end
      end 
    end
  end
end
