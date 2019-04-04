require 'helper'
require 'fluent/plugin/parse_protobuf.rb'

class ProtobufParseTest < Test::Unit::TestCase
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
    Fluent::Test::Driver::Parser.new(Fluent::Plugin::ProtobufParse).configure(conf)
  end

  def test_parse_protobuf(conf = %([]), json_path)
    json_data = JSON.parse!(File.read(json_path))
    expected = json_data['timeseries'].map { |ts|
      Prometheus::TimeSeries.new(ts)
    }

    timeseries = Prometheus::WriteRequest.new(json_data)
    encoded = Prometheus::WriteRequest.encode(timeseries)
    compressed = Snappy.deflate(encoded)

    d = create_driver(conf)
    output = d.instance.parse(compressed)
    assert_equal expected, output
  end
end
