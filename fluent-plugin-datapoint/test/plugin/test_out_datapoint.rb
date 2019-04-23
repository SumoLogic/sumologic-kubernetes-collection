require 'helper'
require 'fluent/plugin/out_datapoint.rb'

class DatapointOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  sub_test_case 'trasform time series with single batch single sample' do
    test 'single datapoint single sample default config' do
      config = %([])
      events = read_events(config, 'test/resources/single.json')
      assert_equal 1, events.length
      assert_equal 'kubernetes.timeseries', events[0][0] # tag
      assert events[0][1].is_a? Fluent::EventTime # time
      expected = JSON.parse!(File.read('test/resources/single.output.json'))
      assert_equal expected, events[0][2] # record
    end

    test 'ignore point with missing value with default config' do
      config = %([])
      events = read_events(config, 'test/resources/single.missing_value.json')
      assert_equal 0, events.length
    end

    test 'ignore point with NaN value with default config' do
      config = %([])
      events = read_events(config, 'test/resources/single.nan_value.json')
      assert_equal 0, events.length
    end
  end

  sub_test_case 'parameters' do
    test '"tag" define the tag of output' do
      config = %([
        tag test_tag
      ])
      events = read_events(config, 'test/resources/single.json')
      assert_equal 1, events.length
      assert_equal 'test_tag', events[0][0] # tag
    end

    test '"missing_values" define the value if "value" is missing in sample' do
      config = %([
        missing_values 6666
      ])
      events = read_events(config, 'test/resources/single.missing_value.json')
      assert_equal 1, events.length
      assert_equal 6666, events[0][2]['@value']
    end

    test '"missing_values" define the value if "value" is NaN in sample' do
      config = %([
        missing_values 6666
      ])
      events = read_events(config, 'test/resources/single.nan_value.json')
      assert_equal 1, events.length
      assert_equal 6666, events[0][2]['@value']
    end
  end

  sub_test_case 'trasform time series with single batch multiple samples' do
    test 'single datapoint multiple samples default config' do
      config = %([])
      events = read_events(config, 'test/resources/multiple.json')
      assert_equal 3, events.length
      expected = JSON.parse!(File.read('test/resources/multiple.output_part.json'))
      assert_equal 'kubernetes.timeseries', events[0][0] # tag
      assert events[0][1].is_a? Fluent::EventTime # time
      assert_equal 1550862324543 / 1000, events[0][1].to_i # time
      assert expected < events[0][2] # record
      assert_equal 1024, events[0][2]['@value'] # value
      assert_equal 'kubernetes.timeseries', events[1][0] # tag
      assert events[1][1].is_a? Fluent::EventTime # time
      assert_equal 1550863744525 / 1000, events[1][1].to_i # time
      assert_equal 1379, events[1][2]['@value'] # value
      assert expected < events[1][2] # record
      assert_equal 'kubernetes.timeseries', events[2][0] # tag
      assert events[2][1].is_a? Fluent::EventTime # time
      assert_equal 1550865342245 / 1000, events[2][1].to_i # time
      assert_equal 986, events[2][2]['@value'] # value
      assert expected < events[2][2] # record
    end

    test 'ignore point with NaN value with default config' do
      config = %([])
      events = read_events(config, 'test/resources/multiple.nan_value.json')
      assert_equal 2, events.length
    end

    test 'ignore point with missing value with default config' do
      config = %([])
      events = read_events(config, 'test/resources/multiple.missing_value.json')
      assert_equal 2, events.length
    end

    test '"missing_values" define the value if "value" is missing in sample' do
      config = %([
        missing_values 66.66
      ])
      events = read_events(config, 'test/resources/multiple.missing_value.json')
      assert_equal 3, events.length
      assert_equal 66.66, events[1][2]['@value']
    end

    test '"missing_values" define the value if "value" is NaN in sample' do
      config = %([
        missing_values 66.66
      ])
      events = read_events(config, 'test/resources/multiple.nan_value.json')
      assert_equal 3, events.length
      assert_equal 66.66, events[1][2]['@value']
    end
  end

  sub_test_case 'trasform time series with multiple batches multiple samples' do
    test 'multiple datapoints multiple samples default config' do
      config = %([])
      events = read_events(config, 'test/resources/timeseries.json')
      assert_equal 60, events.length
    end

    test 'multiple datapoints multiple samples with missing value overriden' do
      config = %([
        missing_values 0
      ])
      events = read_events(config, 'test/resources/timeseries.json')
      assert_equal 108, events.length
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::DatapointOutput).configure(conf)
  end

  def read_events(config, json_path)
    input = JSON.parse!(File.read(json_path))

    d = create_driver(config)
    d.run(default_tag: 'kubernetes.timeseries') do
      d.feed(Fluent::EventTime.now, input)
    end

    d.events
  end
end
