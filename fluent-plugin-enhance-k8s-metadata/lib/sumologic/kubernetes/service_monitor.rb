require 'concurrent'

module SumoLogic
  module Kubernetes
    # module for watching changes to services
    module ServiceMonitor
      require_relative 'connector.rb'

      def start_service_monitor
        log.info "Starting watching for service changes"
        @watch_service_interval_seconds = 300
        thread_create(:"watch_endpoints") {
          loop do
            log.debug "Making new watch_endpoints call"
            params = Hash.new
            params[:as] = :raw
            params[:resource_version] = get_current_service_snapshot_resource_version
            params[:timeout_seconds] = @watch_service_interval_seconds + 60
            @watcher = @clients['v1'].public_send("watch_endpoints", params).tap do |watcher|
              log.debug "@watcher initialized for watch_endpoints"
              watcher.each do |event|
                begin
                  event = JSON.parse(event)
                  log.trace "Got watch_endpoints event #{event}"
                  handle_service_event(event)
                rescue => e
                  log.error "Got exception #{e} parsing event #{event}. Skipping."
                end
              end
              log.debug "Closing watch stream"
            end
          end
        }
      end

      def get_current_service_snapshot_resource_version
        log.debug "Getting current service snapshot"
        begin
          params = Hash.new
          params[:as] = :raw
          response = @clients['v1'].public_send "get_endpoints", params
          result = JSON.parse(response)
          log.debug "Got response to get_endpoints #{result}"
          new_snapshot_pods_to_services = Concurrent::Map.new {|h, k| h[k] = []}

          result['items'].each do |endpoint|
            service = endpoint['metadata']['name']
            get_pods_for_service(endpoint).each {|pod| new_snapshot_pods_to_services[pod] << service}
          end

          log.debug "Reinitializing @pods_to_services to #{new_snapshot_pods_to_services}"
          @pods_to_services = new_snapshot_pods_to_services
          result['metadata']['resourceVersion']
        rescue => e
          log.error "Got exception #{e} getting current service snapshot and corresponding resource version."
          0
        end
      end

      def get_pods_for_service(endpoint)
        pods = []
        if endpoint.key? 'subsets'
          endpoint['subsets'].each do |subset|
            ['addresses', 'notReadyAddresses'].each do |key|
              if subset.key? key
                subset[key].each do |object|
                  if object.key? 'targetRef'
                    if object['targetRef']['kind'] == 'Pod'
                      pod = object['targetRef']['name']
                      log.debug "Found Pod #{pod} for Service #{endpoint['metadata']['name']}"
                      pods << pod
                    end
                  end
                end
              end
            end
          end
        end
        pods
      end

      def handle_service_event(event)
        type = event['type']
        endpoint = event['object']
        service = endpoint['metadata']['name']
        case type
        when 'ADDED'
          get_pods_for_service(endpoint).each {|pod| @pods_to_services[pod] << service unless @pods_to_services[pod].include? service}
        when 'MODIFIED'
          desired_pods = get_pods_for_service(endpoint)
          desired_pods.each {|pod| @pods_to_services[pod] |= [service]}
          @pods_to_services.each do |pod, services|
            if services.include? service
              services.delete service unless desired_pods.include? pod
            end
            @pods_to_services.delete pod if services.length == 0
          end
        when 'DELETED'
          get_pods_for_service(endpoint).each do |pod|
            @pods_to_services[pod].delete service
            @pods_to_services.delete pod if @pods_to_services[pod].length == 0
          end
        else
          log.error "Unknown type for watch endpoint event #{type}"
        end
      end
    end
  end
end