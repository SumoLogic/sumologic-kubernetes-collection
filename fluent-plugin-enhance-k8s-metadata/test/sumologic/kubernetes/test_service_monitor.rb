require 'helper'
require 'sumologic/kubernetes/service_monitor.rb'
require 'fluent/test/log'

class ServiceMonitorTest < Test::Unit::TestCase
  include SumoLogic::Kubernetes::Connector
  include SumoLogic::Kubernetes::ServiceMonitor

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

  def get_test_endpoint
    JSON.parse(File.read("test/resources/endpoints_list.json"))['items']
  end

  sub_test_case 'get_pods_for_service' do
    test 'endpoint with no subsets' do
      input = get_test_endpoint[1]
      assert_equal 0, get_pods_for_service(input).length
    end

    test 'endpoint with subsets and addresses with no targetRef' do
      input = get_test_endpoint[0]
      assert_equal 0, get_pods_for_service(input).length
    end

    test 'endpoint with subsets and addresses with targetRef but type is not Pods' do
      input = get_test_endpoint[4]
      assert_equal 0, get_pods_for_service(input).length
    end

    test 'endpoint with subsets and addresses with targetRef and type is Pods' do
      input = get_test_endpoint[2]
      expected = ['kube-dns-6b4f4b544c-gzl2r', 'kube-dns-6b4f4b544c-98jxv']
      assert_equal expected, get_pods_for_service(input)
    end

    test 'endpoint with subsets and notReadyAddresses with targetRef and type is Pods' do
      input = get_test_endpoint[6]
      expected = ['fluentd-59d9c9656d-cg5m4', 'fluentd-59d9c9656d-5pwjg', 'fluentd-59d9c9656d-zlhjh']
    end
  end
end
