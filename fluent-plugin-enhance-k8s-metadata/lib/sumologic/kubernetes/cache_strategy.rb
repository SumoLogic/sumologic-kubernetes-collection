module SumoLogic
  module Kubernetes
    # module for caching strategy
    module CacheStrategy
      require 'lru_redux'
      require_relative 'reader.rb'

      CACHE_TYPE_POD_LABELS = 'pod_labels'.freeze
      CACHE_TYPE_OWNER_REFS = 'owner_refs'.freeze

      def init_cache
        @all_caches = {
          CACHE_TYPE_POD_LABELS => LruRedux::TTL::ThreadSafeCache.new(@cache_size, @cache_ttl),
          CACHE_TYPE_OWNER_REFS => LruRedux::TTL::ThreadSafeCache.new(@cache_size, @cache_ttl)
        }
      end

      def get_pod_labels(namespace_name, pod_name)
        key = "#{namespace_name}::#{pod_name}"
        cache = @all_caches[@CACHE_TYPE_POD_LABELS]
        labels = cache[key]
        if labels.nil?
          begin
            labels = fetch_pod_labels(namespace_name, pod_name)
          rescue Kubeclient::ResourceNotFoundError => e
            log.error e, "Cannot find pod: #{namespace_name}::#{pod_name}"
            cache[key] = {}
          end
          cache[key] = labels
        end
        labels
      end
    end
  end
end
