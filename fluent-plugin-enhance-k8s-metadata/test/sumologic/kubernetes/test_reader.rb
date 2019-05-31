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

  test 'fetch_pod is expected' do
    pod = fetch_pod('sumologic', 'somepod')
    assert_not_nil pod
    assert_equal pod['apiVersion'], 'v1'
    assert_equal pod['kind'], 'Pod'
  end

  test 'extract_pod_labels is expected' do
    pod = fetch_pod('sumologic', 'somepod')
    assert_not_nil pod
    labels = extract_pod_labels(pod)
    assert_not_nil labels
    assert_equal labels['pod-template-hash'], '1691804713'
    assert_equal labels['run'], 'curl-byi'
  end

  test 'fetch_pod_labels is expected' do
    labels = fetch_pod_labels('sumologic', 'somepod')
    assert_not_nil labels
    assert_equal labels['pod-template-hash'], '1691804713'
    assert_equal labels['run'], 'curl-byi'
  end

  test 'fetch_pod_labels return empty map if resource not found' do
    labels = fetch_pod_labels('non-exist', 'somepod')
    assert_not_nil labels
    assert_equal labels.size, 0
  end
end
