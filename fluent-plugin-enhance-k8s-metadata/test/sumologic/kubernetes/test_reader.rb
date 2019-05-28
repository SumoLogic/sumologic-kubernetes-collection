require 'helper'
require 'sumologic/kubernetes/reader.rb'
require 'fluent/test/log'

class ReaderTest < Test::Unit::TestCase
  include SumoLogic::Kubernetes::Connector
  include SumoLogic::Kubernetes::Reader

  def setup
    # runs before each test
    stub_apis
  end

  def teardown
    # runs after each test
  end

  def log
    Fluent::Test::TestLogger.new
  end

  test 'fetch_pod is expected' do
    connect_kubernetes
    pod = fetch_pod('sumologic', 'somepod')
    assert_not_nil pod
    assert_equal pod['apiVersion'], 'v1'
    assert_equal pod['kind'], 'Pod'
  end

  test 'extract_pod_labels is expected' do
    connect_kubernetes
    pod = fetch_pod('sumologic', 'somepod')
    assert_not_nil pod
    labels = extract_pod_labels(pod)
    assert_not_nil labels
    assert_equal labels['pod-template-hash'], '1691804713'
    assert_equal labels['run'], 'curl-byi'
  end
end
