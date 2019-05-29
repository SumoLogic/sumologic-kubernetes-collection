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

      def fetch_pod_metadata(namespace, pod)
        pod = fetch_resource('pods', pod, namespace)
        return {} if pod.nil?

        metadata = {}

        labels = pod['metadata']['labels']
        metadata['Pod'] = { 'labels' => labels } if labels.is_a?(Hash)

        metadata
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
            result.add(current)
            owner_references = current['ownerReferences']
            begin
              owner_references.each do |owner_reference|
                next if visited.key?(owner_reference['uid'])

                owner = fetch_resource(
                  RESOURCE_MAPPING[owner_reference['kind']],
                  owner_reference['name'],
                  namespace
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
      rescue Kubeclient::ResourceNotFoundError => e
        log.error e
        nil
      end
    end
  end
end
