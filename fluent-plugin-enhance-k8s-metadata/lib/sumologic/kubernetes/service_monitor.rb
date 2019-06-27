require 'concurrent'

module SumoLogic
  module Kubernetes
    # module for watching changes to services
    module ServiceMonitor
      require_relative 'connector.rb'

      def start_service_monitor
        log.info "Starting watching for service changes"

        @watch_service_interval_seconds = 300

        last_recreated = Time.now.to_i
        log.debug "last_recreated initialized to #{last_recreated}"

        while true do
          # Periodically restart watcher connection by checking if enough time has passed since 
          # last time watcher thread was recreated or if the watcher thread has been stopped.
          now = Time.now.to_i
          watcher_exists = Thread.list.select {|thread| thread.object_id == @watcher_id && thread.alive?}.count > 0
          if now - last_recreated >= @watch_service_interval_seconds || !watcher_exists

            log.debug "Recreating service watcher thread"
            @watch_stream.finish if @watch_stream

            start_service_watcher_thread
            last_recreated = now
            log.debug "last_recreated updated to #{last_recreated}"
          end
          sleep(10)
        end
      end

      def start_service_watcher_thread
        log.debug "Starting service endpoints watcher thread"
        params = Hash.new
        params[:as] = :raw
        params[:resource_version] = get_current_service_snapshot_resource_version
        params[:timeout_seconds] = @watch_service_interval_seconds + 60

        @watcher = @clients['v1'].public_send("watch_endpoints", params).tap do |watcher|
          thread_create(:"watch_endpoints") do
            @watch_stream = watcher
            @watcher_id = Thread.current.object_id
            log.debug "New thread to watch service endpoints #{@watcher_id} from resource version #{params[:resource_version]}"

            watcher.each do |event|
              begin
                event = JSON.parse(event)
                handle_service_event(event)
              rescue => e
                log.error "Got exception #{e} parsing entity #{entity}. Skipping."
              end
            end
            log.info "Closing watch stream"
          end
        end
      end

      def get_current_service_snapshot_resource_version
        log.debug "Getting current service snapshot"
        begin
          params = Hash.new
          params[:as] = :raw
          response = @clients['v1'].public_send "get_endpoints", params
          result = JSON.parse(response)
          new_snapshot_pods_to_services = Concurrent::Map.new {|h, k| h[k] = []}

          result['items'].each do |endpoint|
            service = endpoint['metadata']['name']
            get_pods_for_service(endpoint).each {|pod| new_snapshot_pods_to_services[pod] << service}
          end

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
          get_pods_for_service(endpoint).each {|pod| @pods_to_services[pod] << service}
        when 'MODIFIED'
          desired_pods = get_pods_for_service(endpoint)
          @pods_to_services.each do |pod, services|
            if services.include? service
              services.delete service unless desired_pods.include? pod
            end
          end
          desired_pods.each {|pod| @pods_to_services[pod] |= [service]}
        when 'DELETED'
          get_pods_for_service(endpoint).each {|pod| @pods_to_services[pod].delete service}
        else
          log.error "Unknown type for watch endpoint event #{type}"
        end
      end
    end
  end
end