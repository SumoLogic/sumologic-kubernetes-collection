

require "fluent/plugin/output"

module Fluent
  module Plugin
    class DatapointOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("datapoint", self)
    end
  end
end
