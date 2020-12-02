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
    @test_log ||= Fluent::Test::TestLogger.new
  end

  test 'fetch_resource is expected' do
    pod = fetch_resource('pods', 'somepod', 'sumologic')
    assert_not_nil pod
    assert_equal 'v1', pod['apiVersion']
    assert_equal 'Pod', pod['kind']
    labels = pod['metadata']['labels']
    assert_not_nil labels
    assert_equal '1691804713', labels['pod-template-hash']
    assert_equal 'curl-byi', labels['run']
  end

  test 'fetch_pod_metadata get labels' do
    metadata = fetch_pod_metadata('sumologic', 'somepod')
    assert_not_nil metadata
    assert_equal '1691804713', metadata['pod_labels']['pod_labels']['pod-template-hash']
    assert_equal 'curl-byi', metadata['pod_labels']['pod_labels']['run']
  end

  test 'fetch_pod_metadata get owners' do
    metadata = fetch_pod_metadata('kube-system', 'somepod')
    assert_not_nil metadata
    assert_equal 'kube-dns-5fbcb4d67b', metadata['owners']['replicaset']
    assert_equal 'kube-dns', metadata['owners']['deployment']
  end

  test 'fetch_pod_metadata returns empty map if resource not found' do
    metadata = fetch_pod_metadata('non-exist', 'somepod')
    assert_not_nil metadata
    assert_equal 0, metadata.size
    assert log.logs.any? { |log| log.include?('404') }
  end
end
