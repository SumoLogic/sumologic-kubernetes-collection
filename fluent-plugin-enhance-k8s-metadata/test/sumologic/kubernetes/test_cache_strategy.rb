require 'helper'
require 'sumologic/kubernetes/cache_strategy.rb'
require 'fluent/test/log'

class CacheStrategyTest < Test::Unit::TestCase
  include SumoLogic::Kubernetes::Connector
  include SumoLogic::Kubernetes::Reader
  include SumoLogic::Kubernetes::CacheStrategy

  def setup
    # runs before each test
    stub_apis
    connect_kubernetes
    init_cache
  end

  def teardown
    # runs after each test
  end

  def log
    Fluent::Test::TestLogger.new
  end

  test 'get_pod_metadata load labels from API' do
    metadata = get_pod_metadata('sumologic', 'somepod')
    assert_not_nil metadata
    assert_equal metadata['pod']['labels']['pod-template-hash'], '1691804713'
    assert_equal metadata['pod']['labels']['run'], 'curl-byi'
  end

  test 'get_pod_metadata load labels from cache if already exist' do
    assert_not_nil @cache
    @cache['sumologic::somepod'] = {
      'pod' => {
        'labels' => {
          'pod-template-hash' => '0',
          'run' => 'from-cache'
        }
      }
    }
    metadata = get_pod_metadata('sumologic', 'somepod')
    assert_equal metadata['pod']['labels']['pod-template-hash'], '0'
    assert_equal metadata['pod']['labels']['run'], 'from-cache'
  end

  test 'get_pod_metadata cache empty result' do
    assert_not_nil @cache
    @cache['sumologic::somepod'] = {}
    metadata = get_pod_metadata('sumologic', 'somepod')
    assert_not_nil metadata
    assert_equal metadata.size, 0
  end
end
