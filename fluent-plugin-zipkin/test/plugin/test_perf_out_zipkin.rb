require_relative '../helper'
require 'fluent/test/driver/output'
require 'fluent/plugin/output'
require 'fluent/plugin/out_zipkin'
require 'benchmark'

class ZipkinOutputPerformanceTest < ::Test::Unit::TestCase
  SPANS_CHUNK = [[0,
    {
        'trace_id' => 'test_id',
        'parent_id' => 'test_ie',
        'id' => 'test_ic',
        'kind' => 'CLIENT',
        'name' => 'test name',
        'timestamp' => 1580308467000000,
        'duration' => 13,
        'local_endpoint' => {
            'service_name' => 'test_local',
            'ipv4' => "\x7f\x00\x00\x01".force_encoding("ASCII-8BIT"),
            'ipv6' => "\x20\x01\x48\x60\x48\x60\x88\x88".force_encoding("ASCII-8BIT"),
            'port' => 313,
        },
        'remote_endpoint' => {
            'service_name' => 'test_remote',
            'ipv4' => "\x7f\x00\x00\x02".force_encoding("ASCII-8BIT"),
            'ipv6' => "\x20\x01\x48\x60\x48\x60\x88\xff".force_encoding("ASCII-8BIT"),
            'port' => 777,
        },
        'annotations' => [
            {
                'timestamp' => 1580308467000006,
                'value' => 'test_value'
            }
        ],
        'tags' => {
            'tag1' => 'test_first_tag',
            'tag2' => 'test_second_tag'
        }
    }]]

  def setup
    Fluent::Test.setup
    @plugin = Fluent::Test::Driver::Output.new(Fluent::Plugin::ZipkinOutput)
  end

  # def test_protobuf
  #   @plugin.configure(%[
  #       content_type application/x-protobuf
  #       endpoint /dev/null
  #   ])
    
  #   puts 'get_spans'
  #   puts Benchmark.measure {
  #     500_000.times do
  #       @plugin.instance.send(:get_spans, SPANS_CHUNK)
  #     end
  #   }
    
  #   puts 'get_spans_for_json'
  #   puts Benchmark.measure {
  #     100.times do
  #       @plugin.instance.send(:get_spans_for_json, SPANS_CHUNK.clone)
  #     end
  #   }
  # end

end