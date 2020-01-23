require 'helper'
require 'fluent/plugin/filter_enhance_k8s_metadata.rb'
require 'sumologic/kubernetes/record_decorator.rb'
require 'sumologic/kubernetes/cache_strategy.rb'
require 'fluent/test/log'
require 'fluent/plugin/filter'

class RecordDecoratorTest < Test::Unit::TestCase
  include SumoLogic::Kubernetes::Connector
  include SumoLogic::Kubernetes::Reader
  include SumoLogic::Kubernetes::CacheStrategy
  include SumoLogic::Kubernetes::RecordDecorator

  include Fluent::PluginHelper::RecordAccessor

  def setup
    # runs before each test
    Fluent::Test.setup
    stub_apis
    connect_kubernetes
    init_cache

    @in_namespace_ac = ['$.namespace'].map { |path| record_accessor_create(path) }
    @in_pod_ac = ['$.pod', '$.pod_name'].map { |path| record_accessor_create(path) }

    @pods_to_services = {}
  end

  def teardown
    # runs after each test
  end

  def log
    @logger ||= Fluent::Test::TestLogger.new
  end

  test 'decorating record performance' do
    (1..1000).map do |pod_number|
      @cache["sumologic::pod-#{pod_number}"] = {
          'pod_labels' => {
              'pod_labels' => {
                  'pod-template-hash' => "hash-#{pod_number}",
                  'run' => 'from-cache'
              }
          }
      }
    end

    records = (1..1000).map do |i|
      {'namespace' => 'sumologic', 'pod' => "pod-#{i}", 'service'=> 'prometheus', 'metric1' => i, 'metric2' => i*100}
    end

    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    processed_count = 0

    10.times do
      records.each do |record|
        decorate_record(record)
        processed_count += 1
      end
    end

    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = ending - starting
    records_per_sec = processed_count / elapsed

    print("decorate_record: #{processed_count} records in #{elapsed.round(2)} " +
          "seconds or #{records_per_sec.to_i} records/s\n" % elapsed)
  end

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::EnhanceK8sMetadataFilter).configure(conf)
  end
end
