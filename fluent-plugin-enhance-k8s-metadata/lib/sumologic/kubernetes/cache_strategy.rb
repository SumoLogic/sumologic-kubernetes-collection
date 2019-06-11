module SumoLogic
  module Kubernetes
    # module for caching strategy
    module CacheStrategy
      require 'lru_redux'
      require_relative 'reader.rb'

      def init_cache
        @cache = LruRedux::TTL::ThreadSafeCache.new(@cache_size, @cache_ttl)
      end

      def get_pod_metadata(namespace_name, pod_name)
        key = "#{namespace_name}::#{pod_name}"
        metadata = @cache[key]
        if metadata.nil?
          metadata = fetch_pod_metadata(namespace_name, pod_name)
          @cache[key] = metadata
        end
        metadata
      end
    end
  end
end
