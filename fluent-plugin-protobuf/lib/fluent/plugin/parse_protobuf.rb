require 'fluent/plugin/parser'
require 'base64'
require 'google/protobuf'
require 'snappy'
require_relative '../../types_pb'
require_relative '../../remote_pb'

module Fluent
  module Plugin
    # fluentd parser plugin to parse Prometheus metrics into timeseries events.
    class ProtobufParse < Fluent::Plugin::Parser
      Fluent::Plugin.register_parser('protobuf', self)

      def parse(text)
        begin
          inflated = Snappy.inflate(text)
          decoded = Prometheus::WriteRequest.decode(inflated)
          decoded.timeseries.map { |ts|
            log.debug(ts)
            ts
          }
        rescue StandardError => exception
          log.error('ERROR during decoding', error: exception)
        end
      end
    end
  end
end
