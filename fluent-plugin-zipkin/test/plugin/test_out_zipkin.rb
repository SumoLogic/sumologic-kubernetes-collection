require_relative '../helper'
require 'fluent/test/driver/output'
require 'fluent/plugin/output'
require 'fluent/plugin_helper/socket'
require 'fluent/plugin/out_zipkin'

class ZipkinOutputTest < ::Test::Unit::TestCase
  EXPECTED_JSON = '[{"traceId":"746573745f6964","parentId":"746573745f6965","id":"746573745f6963","kind":"CLIENT","name":"test name","timestamp":1580308467000000,"duration":13,"localEndpoint":{"serviceName":"test_local","ipv4":"127.0.0.1","ipv6":"::2001:4860:4860:8888","port":313},"remoteEndpoint":{"serviceName":"test_remote","ipv4":"127.0.0.2","ipv6":"::2001:4860:4860:88ff","port":777},"annotations":[{"timestamp":1580308467000006,"value":"test_value"}],"tags":{"tag1":"test_first_tag","tag2":"test_second_tag"}}]'
  EXPECTED_PROTOBUF = "\x0a\xbe\x01\x0a\x07\x74\x65\x73\x74\x5f\x69\x64\x12\x07\x74\x65\x73\x74\x5f\x69\x65\x1a\x07\x74\x65\x73\x74\x5f\x69\x63\x20\x01\x2a\x09\x74\x65\x73\x74\x20\x6e\x61\x6d\x65\x31\xc0\xa2\xcf\x3c\x48\x9d\x05\x00\x38\x0d\x42\x1f\x0a\x0a\x74\x65\x73\x74\x5f\x6c\x6f\x63\x61\x6c\x12\x04\x7f\x00\x00\x01\x1a\x08\x20\x01\x48\x60\x48\x60\x88\x88\x20\xb9\x02\x4a\x20\x0a\x0b\x74\x65\x73\x74\x5f\x72\x65\x6d\x6f\x74\x65\x12\x04\x7f\x00\x00\x02\x1a\x08\x20\x01\x48\x60\x48\x60\x88\xff\x20\x89\x06\x52\x15\x09\xc6\xa2\xcf\x3c\x48\x9d\x05\x00\x12\x0a\x74\x65\x73\x74\x5f\x76\x61\x6c\x75\x65\x5a\x16\x0a\x04\x74\x61\x67\x31\x12\x0e\x74\x65\x73\x74\x5f\x66\x69\x72\x73\x74\x5f\x74\x61\x67\x5a\x17\x0a\x04\x74\x61\x67\x32\x12\x0f\x74\x65\x73\x74\x5f\x73\x65\x63\x6f\x6e\x64\x5f\x74\x61\x67"
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

  def test_protobuf
    @plugin.configure(%[
        content_type application/x-protobuf
        endpoint /dev/null
    ])

    chunk = [[0,
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
    spans = @plugin.instance.send(:get_spans, chunk)

    assert_equal(spans[0], EXPECTED_PROTOBUF.force_encoding("ASCII-8BIT"))
  end

  def test_json
    @plugin.configure(%[
        content_type application/json
        endpoint /dev/null
    ])

    chunk = [[0,
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

    spans = @plugin.instance.send(:get_spans_for_json, SPANS_CHUNK)

    assert_equal(Oj.load(spans[0], mode: :compat), Oj.load(EXPECTED_JSON, mode: :compat))
  end

  def test_json_empty_parent_id
    expected_json = '[{"traceId":"746573745f6964","id":"746573745f6963","kind":"CLIENT","name":"test name","timestamp":1580308467000000,"duration":13,"localEndpoint":{"serviceName":"test_local","port":313},"remoteEndpoint":{"serviceName":"test_remote","port":777},"annotations":[{"timestamp":1580308467000006,"value":"test_value"}],"tags":{"tag1":"test_first_tag","tag2":"test_second_tag"}}]'
    @plugin.configure(%[
        content_type application/json
        endpoint /dev/null
    ])

    chunk = [[0,
      {
        'trace_id' => 'test_id',
        'parent_id' => '',
        'id' => 'test_ic',
        'kind' => 'CLIENT',
        'name' => 'test name',
        'timestamp' => 1580308467000000,
        'duration' => 13,
        'local_endpoint' => {
            'service_name' => 'test_local',
            'ipv4' => "".force_encoding("ASCII-8BIT"),
            'ipv6' => "".force_encoding("ASCII-8BIT"),
            'port' => 313,
        },
        'remote_endpoint' => {
            'service_name' => 'test_remote',
            'ipv4' => "".force_encoding("ASCII-8BIT"),
            'ipv6' => "".force_encoding("ASCII-8BIT"),
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

    spans = @plugin.instance.send(:get_spans_for_json, chunk)

    assert_equal(Oj.load(spans[0], mode: :compat), Oj.load(expected_json, mode: :compat))
  end
end