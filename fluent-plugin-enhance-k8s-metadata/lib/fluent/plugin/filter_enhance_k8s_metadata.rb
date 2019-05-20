require 'fluent/plugin/filter'

module Fluent
  module Plugin
    # fluentd filter plugin for appending Kubernetes metadata to events
    class EnhanceK8sMetadataFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter('enhance_k8s_metadata', self)

      def filter(tag, time, record)
      end
    end
  end
end
