module SumoLogic
  module Kubernetes
    # module for reading from Kubernetes API server
    module Reader
      require_relative 'connector.rb'

      MAX_BFS_DEPTH = 8

      # from https://kubernetes.io/docs/reference/kubectl/overview/#resource-types
      RESOURCE_MAPPING = {
        'ConfigMap' => 'configmaps',
        'ControllerRevision' => 'controllerrevisions',
        'CronJob' => 'cronjobs',
        'DaemonSet' => 'daemonsets',
        'Deployment' => 'deployments',
        'Endpoints' => 'endpoints',
        'Event' => 'events',
        'HorizontalPodAutoscaler' => 'horizontalpodautoscalers',
        'Ingress' => 'ingresses',
        'Job' => 'jobs',
        'Lease' => 'leases',
        'LimitRange' => 'limitranges',
        'LocalSubjectAccessReview' => 'localsubjectaccessreviews',
        'NetworkPolicy' => 'networkpolicies',
        'PersistentVolumeClaim' => 'persistentvolumeclaims',
        'Pod' => 'pods',
        'PodDisruptionBudget' => 'poddisruptionbudgets',
        'PodTemplate' => 'podtemplates',
        'ReplicaSet' => 'replicasets',
        'ReplicationController' => 'replicationcontrollers',
        'ResourceQuota' => 'resourcequotas',
        'Role' => 'roles',
        'RoleBinding' => 'rolebindings',
        'Secret' => 'secrets',
        'Service' => 'services',
        'ServiceAccount' => 'serviceaccounts',
        'StatefulSet' => 'statefulsets'
      }.freeze

      def fetch_pod(namespace_name, pod_name)
        fetch_resource('pods', pod_name, namespace_name)
      end

      def extract_pod_labels(pod)
        if pod.nil?
          log.warn 'pod is nil'
        elsif pod['metadata'].nil?
          log.warn 'metadata is nil'
        elsif pod['metadata']['labels'].nil?
          log.warn 'labels is nil'
        else
          pod['metadata']['labels']
        end
      end

      def fetch_pod_labels(namespace_name, pod_name)
        extract_pod_labels(fetch_pod(namespace_name, pod_name))
      rescue Kubeclient::ResourceNotFoundError => e
        log.error e
        # TODO: we now cache empty if not found since some namespace/pod not matching
        {}
      end

      def fetch_owners(namespace_name, resource)
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
            result.add(current)
            owner_references = current['ownerReferences']
            begin
              owner_references.each do |owner_reference|
                next if visited.key?(owner_reference['uid'])

                owner = fetch_resource(
                  RESOURCE_MAPPING[owner_reference['kind']],
                  owner_reference['name'],
                  namespace_name
                )
                queue.push(owner)
                visited[owner_reference['uid']] = owner
              end
            rescue StandardError => e
              log.error e
            end
          end
          depth += 1
        end
        result
      end

      def fetch_resource(type, name, namespace)
        log.info "fetching resource: #{type}, name: #{name}, ns:#{namespace}"
        resource = @client.get_entity(type, name, namespace)
        log.debug resource.to_s
        resource
      end
    end
  end
end
