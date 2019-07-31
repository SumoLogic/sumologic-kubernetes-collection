require 'fluent/plugin/parser'
require 'google/protobuf'
require 'snappy'
require_relative '../../types_pb'
require_relative '../../remote_pb'

WriteRequest = Prometheus::WriteRequest

module Fluent
  module Plugin
    # fluentd parser plugin to parse Prometheus metrics into timeseries events.
    class ProtobufParser < Fluent::Plugin::Parser
      Fluent::Plugin.register_parser('protobuf', self)

      KEY_TIMESERIES = 'timeseries'.freeze

      def parse(text)
        inflated = Snappy.inflate(text)
        decoded = WriteRequest.decode(inflated)
        log.trace "protobuf::parse - in: (#{text.bytesize}/#{inflated.bytesize}), out: #{decoded.timeseries.length}"
        record = {}
        record[KEY_TIMESERIES] = decoded.timeseries
        yield Fluent::EventTime.now, record
      end
    end
  end
end
