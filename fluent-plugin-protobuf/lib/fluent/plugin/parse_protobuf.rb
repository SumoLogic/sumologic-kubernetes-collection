require "fluent/plugin/parser"
require 'base64'
require 'google/protobuf'
require 'snappy'
require_relative '../../types_pb'
require_relative '../../remote_pb'

module Fluent
  module Plugin
    class ProtobufParse < Fluent::Plugin::Parser
      Fluent::Plugin.register_parser("protobuf", self)

      def parse(text)
        begin
          inflated = Snappy.inflate(text)
          decoded = Prometheus::WriteRequest.decode(inflated)
          decoded.timeseries.map { |ts|
            log.debug(ts)
            ts
          }
        rescue => e
          log.error("ERROR during decoding: #{e.message}")
          nil
        end
      end
    end
  end
end
