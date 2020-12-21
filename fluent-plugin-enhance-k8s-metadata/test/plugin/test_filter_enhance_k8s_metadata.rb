require 'helper'
require 'fluent/plugin/filter_enhance_k8s_metadata.rb'

class EnhanceK8sMetadataFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    stub_apis
    @pods_to_services = Concurrent::Map.new {|h, k| h[k] = []}
  end

  test 'create driver' do
    conf = %{
      kubernetes_url http://localhost:8080
    }
    create_driver(conf)
  end

  sub_test_case 'filter' do
    test 'get deployment and replicaset for logs' do
      conf = %{
        kubernetes_url http://localhost:8080
        in_namespace_path '$.kubernetes.namespace_name'
        in_pod_path '$.kubernetes.pod_name'
        data_type logs
      }
      driver = create_driver(conf)
      record = driver.filter('tag', 'time', get_test_record[0])

      assert_equal 'curl-byi-5bf5d48c57', record['kubernetes']['replicaset']
      assert_equal 'curl-byi', record['kubernetes']['deployment']
    end

    test 'get deployment and replicaset and pod labels for metrics' do
      conf = %{
        kubernetes_url http://localhost:8080
        data_type metrics
      }
      driver = create_driver(conf)
      record = driver.filter('tag', 'time', get_test_record[1])

      expected_pod_labels = {"pod-template-hash": "1691804713", "run": "curl-byi"}
      assert_equal expected_pod_labels.keys.length, record['pod_labels'].keys.length
      record['pod_labels'].each do |k,v|
        assert_equal expected_pod_labels[k.to_sym], v
      end

      assert_equal 'curl-byi-5bf5d48c57', record['replicaset']
      assert_equal 'curl-byi', record['deployment']
    end

    test 'attach node metadata to metrics when missing' do
      conf = %{
        kubernetes_url http://localhost:8080
        data_type metrics
      }
      driver = create_driver(conf)

      input_record = get_test_record[2]
      assert_nil input_record['node']
      record = driver.filter('tag', 'time', input_record)

      assert_equal 'ip-172-20-62-242.us-west-1.compute.internal', record['node']
    end
  end

  private

  def create_driver(conf)
    driver = Fluent::Test::Driver::Filter.new(Fluent::Plugin::EnhanceK8sMetadataFilter).configure(conf).instance
    driver
  end

  def get_test_record
    JSON.parse(File.read("test/resources/records.json"))['items']
  end
end
