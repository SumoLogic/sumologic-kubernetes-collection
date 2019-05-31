module SumoLogic
  module Kubernetes
    # module for reading from Kubernetes API server
    module Reader
      require_relative 'connector.rb'

      MAX_BFS_DEPTH = 8

      # from https://kubernetes.io/docs/reference/kubectl/overview/#resource-types
      RESOURCE_MAPPING = {
        'DaemonSet' => 'daemonsets',
        'Deployment' => 'deployments',
        'Pod' => 'pods',
        'ReplicaSet' => 'replicasets',
        'Service' => 'services',
        'StatefulSet' => 'statefulsets'
      }.freeze

      def fetch_pod_metadata(namespace, pod)
        pod = fetch_resource('pods', pod, namespace)
        return {} if pod.nil?

        metadata = {}
        labels = pod['metadata']['labels']
        metadata['pod'] = { 'labels' => labels } if labels.is_a?(Hash)

        owners = fetch_pod_owners(namespace, pod)
        metadata.merge!(owners)
        metadata
      end

      def fetch_pod_owners(namespace, pod)
        owners = fetch_owners(namespace, pod)
        result = {}
        owners.each do |owner|
          result[owner['kind'].downcase] = { 'name' => owner['metadata']['name'] }
        end
        result
      end

      def fetch_owners(namespace, resource)
        # BFS for owners
        result = []
        depth = 0
        queue = [resource]
        visited = {
          resource['metadata']['uid'] => resource
        }
        while !queue.empty? && depth <= MAX_BFS_DEPTH
          size = queue.size
          [1..size].each do
            current = queue.shift
            result << current unless current == resource

            owner_references(current).each do |owner_reference|
              begin
                if visited.key?(owner_reference['uid'])
                  log.debug "#{owner_reference['name']} visted."
                  next
                end

                kind = owner_reference['kind']
                unless RESOURCE_MAPPING.key?(kind)
                  log.warn "not supported resource #{kind}"
                  next
                end

                owner = fetch_resource(
                  RESOURCE_MAPPING[owner_reference['kind']],
                  owner_reference['name'],
                  namespace,
                  owner_reference['apiVersion']
                )

                if owner.nil?
                  log.warn "failed to fetch resource: #{type}, name: #{name}, ns:#{namespace} with API version #{api_version}"
                  next
                end
                queue.push(owner)
                visited[owner_reference['uid']] = owner
              rescue StandardError => e
                log.error e
              end
            end
          end
          depth += 1
        end
        result
      end

      def owner_references(resource)
        result = resource['metadata']['ownerReferences']
        if !result.is_a?(Array)
          log.debug "#{resource['metadata']['name']} doesn't have owner (#{result})."
          []
        else
          log.debug "ownerReferences = #{result}"
          result
        end
      rescue StandardError => e
        log.error e
        []
      end

      def fetch_resource(type, name, namespace, api_version = 'v1')
        log.debug "fetching resource: #{type}, name: #{name}, ns:#{namespace} with API version #{api_version}"
        if @clients.key?(api_version)
          resource = @clients[api_version].get_entity(type, name, namespace)
          log.debug resource.to_s
          resource
        else
          log.warn "No client created for API #{api_version}"
          nil
        end
      rescue Kubeclient::ResourceNotFoundError => e
        log.error e
        nil
      end
    end
  end
end
