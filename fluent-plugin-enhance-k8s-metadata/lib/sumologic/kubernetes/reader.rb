module SumoLogic
  module Kubernetes
    # module for reading from Kubernetes API server
    module Reader
      require_relative 'connector.rb'

      def fetch_pod(namespace_name, pod_name)
        log.info "fetching pod metadata: #{namespace_name}::#{pod_name}"
        pod = @client.get_pod(pod_name, namespace_name)
        log.debug "raw metadata for #{namespace_name}::#{pod_name}: #{pod}"
        pod
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
    end
  end
end
