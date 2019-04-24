require 'helper'
require 'fluent/plugin/parser_protobuf.rb'

class ProtobufParserTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  sub_test_case 'single batch single sample' do
    test 'single batch single sample' do
      test_parse_protobuf('test/resources/single.json')
    end

    test 'single batch single sample with missing value' do
      test_parse_protobuf('test/resources/single.missing_value.json')
    end

    test 'single batch single sample with NaN value' do
      test_parse_protobuf('test/resources/single.nan_value.json')
    end
  end

  sub_test_case 'single batch multiple samples' do
    test 'single batch multiple samples' do
      test_parse_protobuf('test/resources/multiple.json')
    end

    test 'single batch multiple samples with missing value' do
      test_parse_protobuf('test/resources/multiple.missing_value.json')
    end

    test 'single batch multiple samples with NaN value' do
      test_parse_protobuf('test/resources/multiple.nan_value.json')
    end
  end

  sub_test_case 'multiple batches multiple samples' do
    test 'multiple datapoints multiple samples' do
      test_parse_protobuf('test/resources/timeseries.json')
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Parser.new(Fluent::Plugin::ProtobufParser).configure(conf)
  end

  def test_parse_protobuf(json_path, conf = %([]))
    json_data = JSON.parse!(File.read(json_path))
    expected = json_data['timeseries'].map do |ts|
      Prometheus::TimeSeries.new(ts)
    end

    timeseries = Prometheus::WriteRequest.new(json_data)
    encoded = Prometheus::WriteRequest.encode(timeseries)
    compressed = Snappy.deflate(encoded)

    create_driver(conf).instance.parse(compressed) do |time, record|
      assert time.is_a? Fluent::EventTime
      assert_equal expected, record['timeseries']
    end
  end
end
