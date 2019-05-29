require 'helper'
require 'sumologic/kubernetes/reader.rb'
require 'fluent/test/log'

class ReaderTest < Test::Unit::TestCase
  include SumoLogic::Kubernetes::Connector
  include SumoLogic::Kubernetes::Reader

  def setup
    # runs before each test
    stub_apis
    connect_kubernetes
  end

  def teardown
    # runs after each test
  end

  def log
    Fluent::Test::TestLogger.new
  end

  test 'fetch_resource is expected' do
    pod = fetch_resource('pods', 'somepod', 'sumologic')
    assert_not_nil pod
    assert_equal pod['apiVersion'], 'v1'
    assert_equal pod['kind'], 'Pod'
    labels = pod['metadata']['labels']
    assert_not_nil labels
    assert_equal labels['pod-template-hash'], '1691804713'
    assert_equal labels['run'], 'curl-byi'
  end

  test 'fetch_pod_metadata is expected' do
    metadata = fetch_pod_metadata('sumologic', 'somepod')
    assert_not_nil metadata
    assert_equal metadata['Pod']['labels']['pod-template-hash'], '1691804713'
    assert_equal metadata['Pod']['labels']['run'], 'curl-byi'
  end

  test 'fetch_pod_metadata returns empty map if resource not found' do
    metadata = fetch_pod_metadata('non-exist', 'somepod')
    assert_not_nil metadata
    assert_equal metadata.size, 0
  end
end
