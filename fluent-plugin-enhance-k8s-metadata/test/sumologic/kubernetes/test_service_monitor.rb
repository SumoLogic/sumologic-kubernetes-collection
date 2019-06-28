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

  sub_test_case 'get_current_service_snapshot_resource_version' do
    test 'get_current_service_snapshot_resource_version' do
      resource_version = get_current_service_snapshot_resource_version
      assert_equal "123456789", resource_version

      expected = {
        "kube-dns-6b4f4b544c-gzl2r": ["kube-dns"],
        "kube-dns-6b4f4b544c-98jxv": ["kube-dns"],
        "tiller-deploy-69458576b-27mp8": ["tiller-deploy"],
        "fluentd-59d9c9656d-cg5m4": ["fluentd"],
        "fluentd-59d9c9656d-5pwjg": ["fluentd"],
        "fluentd-59d9c9656d-zlhjh": ["fluentd"]
      }

      @pods_to_services.each do |k,v|
        assert_equal expected[k.to_sym], v
      end

      assert_equal 6, expected.keys.length
    end
  end
end
