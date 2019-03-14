

require "fluent/plugin/filter"

module Fluent
  module Plugin
    class CarbonV2Filter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("carbon_v2", self)

      def filter(tag, time, record)
      end
    end
  end
end
