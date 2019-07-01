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
    @pods_to_services = Concurrent::Map.new {|h, k| h[k] = []}
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

  def get_test_endpoint_event
    JSON.parse(File.read("test/resources/endpoints_events.json"))['items']
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
      assert_equal expected.keys.length, @pods_to_services.keys.length
      @pods_to_services.each do |k,v|
        assert_equal expected[k.to_sym], v
      end
    end
  end

  sub_test_case 'handle_service_event' do
    test 'ADDED event with no pods' do
      event = get_test_endpoint_event[0]
      handle_service_event(event)
      assert_equal 0, @pods_to_services.keys.length
    end

    test 'ADDED event with new pods' do
      event = get_test_endpoint_event[1]
      handle_service_event(event)

      expected = {
        "fluentd-59d9c9656d-gvhxz": ["fluentd"],
        "fluentd-59d9c9656d-rtp7d": ["fluentd"],
        "fluentd-59d9c9656d-nvhkg": ["fluentd"],
        "fluentd-events-76c68bc596-5clcp": ["fluentd"]
      }
      assert_equal expected.keys.length, @pods_to_services.keys.length
      @pods_to_services.each do |k,v|
        assert_equal expected[k.to_sym], v
      end
    end

    test 'ADDED event with existing service on existing pods' do # shouldn't happen but check anyway
      current_state = {
        "fluentd-59d9c9656d-gvhxz": ["fluentd"],
        "fluentd-59d9c9656d-rtp7d": ["fluentd"],
        "fluentd-59d9c9656d-nvhkg": ["fluentd"],
        "fluentd-events-76c68bc596-5clcp": ["fluentd"]
      }
      current_state.each do |k,v|
        @pods_to_services[k.to_s] = v
      end

      event = get_test_endpoint_event[1]
      handle_service_event(event)
      expected = current_state
      assert_equal expected.keys.length, @pods_to_services.keys.length
      @pods_to_services.each do |k,v|
        assert_equal expected[k.to_sym], v
      end
    end

    test 'ADDED event with new service on existing pods' do
      current_state = {
        "fluentd-59d9c9656d-gvhxz": ["fluentd"],
        "fluentd-59d9c9656d-rtp7d": ["fluentd"],
        "fluentd-59d9c9656d-nvhkg": ["fluentd"],
        "fluentd-events-76c68bc596-5clcp": ["fluentd"]
      }
      current_state.each do |k,v|
        @pods_to_services[k.to_s] = v
      end

      event = get_test_endpoint_event[2]
      handle_service_event(event)
      expected = {
        "fluentd-59d9c9656d-gvhxz": ["fluentd", "fluentd-2"],
        "fluentd-59d9c9656d-rtp7d": ["fluentd", "fluentd-2"],
        "fluentd-59d9c9656d-nvhkg": ["fluentd", "fluentd-2"],
        "fluentd-events-76c68bc596-5clcp": ["fluentd", "fluentd-2"]
      }
      assert_equal expected.keys.length, @pods_to_services.keys.length
      @pods_to_services.each do |k,v|
        assert_equal expected[k.to_sym], v
      end
    end
  end
end
