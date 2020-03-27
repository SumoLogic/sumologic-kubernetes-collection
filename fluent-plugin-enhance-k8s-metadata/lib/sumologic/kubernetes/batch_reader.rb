module SumoLogic
    module Kubernetes
      # module for reading from Kubernetes API server
      module BatchReader
        require_relative 'connector.rb'
        
        @pods_to_resource_types = Concurrent::Map.new {|h, k| h[k] = {}}

        def fetch_batch_resource(type, api_version = 'v1')
          #log.debug "fetching resource: #{type}, name: #{name}, ns:#{namespace} with API version #{api_version}"
          if @clients.key?(api_version)
            batch_resource = []
            continue = nil
            loop do
              entities = @clients[api_version].get_entity(type, limit: 1000, continue: continue)
              continue = entities.continue
              batch_resource.concat(entities)
              break if entities.last?
            end
            log.debug entities.to_s
            entities
          else
            log.warn "No client created for API #{api_version}"
            nil
          end
        rescue Kubeclient::ResourceNotFoundError => e
          log.warn e
          nil
        end
        
        def watchMonitor(type, resource_version)
          log.info "Starting watching for #{type} changes"
          @watch_service_interval_seconds = 300
          thread_create(:"watch_#{type}") {
            loop do
              log.debug "Making new watch_endpoints call"
              params = Hash.new
              params[:as] = :parsed
              params[:resource_version] = resource_version
              params[:timeout_seconds] = @watch_service_interval_seconds + 60
              @watcher = @clients['v1'].public_send("watch_#{type}", params).tap do |watcher|
                log.debug "@watcher initialized for watch_#{type}"
                watcher.each do |event|
                  begin
                    log.trace "Got watch_#{type} event #{event}"
                    handle_watch_event(event)
                  rescue => e
                    log.error "Got exception #{e} parsing event #{event}. Skipping."
                  end
                end
                log.debug "Closing watch stream"
              end
            end
          }
        end

        def get_pods_for_label_selectors(label_selector, namespace)
          pods = []
          entities = @clients[api_version].get_entity('pods', namespace: namespace, label_selector: label_selector)
          if entities.key? items
            entities['items'].each do |item|
              pod = item['metadata']['name']
              log.debug "Found Pod #{pod} for label selector #{label_selector}"
              pods << pod
          end
          pods
        end

        def handle_watch_event(event)
          event_type = event['type']
          label_selector = event['object']['spec']['selector']['matchLabels']['name']
          type = event['object']['kind']
          type_resource_name = event['object']['metadata']['name']
          namespace = event['object']['metadata']['namespace']
          case event_type
          when 'ADDED'
            get_pods_for_label_selectors(label_selector).each do |pod| 
              @pods_to_resource_types[pod]["#{type}"] << type_resource_name unless @pods_to_resource_types[pod]["#{type}"].include? type_resource_name}
          when 'MODIFIED'
            desired_pods = get_pods_for_label_selectors(label_selector, namespace)
            desired_pods.each {|pod| @pods_to_resource_types[pod]["#{type}"] |= [type_resource_name]}
            @pods_to_resource_types.each do |pod, values|
              values.each do |entity_type, resource_names|
                if entity_type == type and resource_names.include? type_resource_name
                  resource_names.delete type_resource_name unless desired_pods.include? pod
                end
                @pods_to_resource_types.delete pod if "#{type}".length == 0
              end
            end
          when 'DELETED'
            continue
          else
            log.error "Unknown type for watch #{type} event #{event_type}"
          end
        end