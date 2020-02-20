require 'fluent/plugin/parser'
require 'google/protobuf'
require 'snappy'
require_relative '../../zipkin_pb'
require 'base64'
require 'oj'
require 'ipaddr'

module Fluent
  module Plugin
    # fluentd parser plugin to parse Prometheus metrics into timeseries events.
    class ZipkinProtobufParser < Fluent::Plugin::Parser
      Fluent::Plugin.register_parser('zipkin_protobuf', self)

      KEY_TIMESERIES = 'timeseries'.freeze

      def hexstring_to_base64(value)
        if !value then
          return value
        end
        return Base64.strict_encode64(Array(value).pack('H*'))
      end

      def hexstring_to_string(value)
        if !value then
          return value
        end

        return Array(value).pack('H*')
      end

      def ip_to_string(value)
        if !value
          return value
        end
        
        return IPAddr.new(value).hton
      end

      def parse_json(text)
        records = Oj.load(text, mode: :compat)
        records.each do |record|
          if value = record.delete('traceId')
            record['trace_id'] = hexstring_to_string(value)
          end
          if value = record.delete('parentId')
            record['parent_id'] = hexstring_to_string(value)
          end
          record['id'] = hexstring_to_string(record['id'])

          record['local_endpoint'] = record.delete('localEndpoint')
          record['remote_endpoint'] = record.delete('remoteEndpoint')

          if record['local_endpoint'] then
            if value = record['local_endpoint'].delete('serviceName')
              record['local_endpoint']['service_name'] = value
            end
            if value = record['local_endpoint'].delete('ipv4')
              record['local_endpoint']['ipv4'] = ip_to_string(value)
            end
            if value = record['local_endpoint'].delete('ipv6')
              record['local_endpoint']['ipv6'] = ip_to_string(value)
            end
          end

          if record['remote_endpoint'] then
            if value = record['remote_endpoint'].delete('serviceName')
              record['remote_endpoint']['service_name'] = value
            end
            if value = record['remote_endpoint'].delete('ipv4')
              record['remote_endpoint']['ipv4'] = ip_to_string(value)
            end
            if value = record['remote_endpoint'].delete('ipv6')
              record['remote_endpoint']['ipv6'] = ip_to_string(value)
            end
          end

          record['timestamp'] = record['timestamp'].to_i
          record['duration'] = record['duration'].to_i

          record['annotations'].each do |annotation|
            annotation['timestamp'] = annotation['timestamp'].to_i
          end

          record['debug'] = !!record['debug']
          record['shared'] = !!record['shared']

          yield record['timestamp'], record
        end
      end

      def parse(text)
        begin
          decoded = Zipkin::Proto3::ListOfSpans.decode(text)
          decoded.spans.each do |span|
            yield span['timestamp'], span.to_h
          end
        rescue Exception => exception
          log.info exception
        end
      end
    end
  end
end
