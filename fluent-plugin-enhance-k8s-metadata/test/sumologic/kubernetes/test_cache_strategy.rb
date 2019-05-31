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

  test 'get_pod_labels load labels from API' do
    labels = get_pod_labels('sumologic', 'somepod')
    assert_not_nil labels
    assert_equal labels['pod-template-hash'], '1691804713'
    assert_equal labels['run'], 'curl-byi'
  end

  test 'get_pod_labels load labels from cache if already exist' do
    cache = @all_caches[CACHE_TYPE_POD_LABELS]
    assert_not_nil cache
    cache['sumologic::somepod'] = {
      'pod-template-hash' => '0',
      'run' => 'from-cache'
    }
    labels = get_pod_labels('sumologic', 'somepod')
    assert_not_nil labels
    assert_equal labels['pod-template-hash'], '0'
    assert_equal labels['run'], 'from-cache'
  end

  test 'get_pod_labels cache empty result' do
    cache = @all_caches[CACHE_TYPE_POD_LABELS]
    assert_not_nil cache
    cache['sumologic::somepod'] = {}
    labels = get_pod_labels('sumologic', 'somepod')
    assert_not_nil labels
    assert_not_nil labels.size, 0
  end
end
