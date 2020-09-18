$LOAD_PATH.unshift(File.expand_path("../../", __FILE__))
require "test-unit"
require "fluent/test"
require "fluent/test/driver/input"
require "fluent/test/helpers"
require 'mocha/test_unit'
require 'webmock/test_unit'

Test::Unit::TestCase.include(Fluent::Test::Helpers)
Test::Unit::TestCase.extend(Fluent::Test::Helpers)

def test_resource(name)
  File.new("test/resources/#{name}")
end

def stub_apis
  stub_request(:any, %r{/api$})
  .to_return(
    'body' => {
      'versions' => ['v1']
    }.to_json
  )
stub_request(:any, %r{/apis$})
  .to_return(
    'body' => {
      'versions' => ['events.k8s.io/v1beta1']
    }.to_json
  )
stub_request(:any, %r{/apis/events.k8s.io$})
  .to_return(
    status: 200,
    body: '{
      "kind": "APIGroup",
      "apiVersion": "v1",
      "name": "events.k8s.io",
      "versions": [
        {
          "groupVersion": "events.k8s.io/v1beta1",
          "version": "v1beta1"
        }
      ],
      "preferredVersion": {
        "groupVersion": "events.k8s.io/v1beta1",
        "version": "v1beta1"
      }
    }',
  )
end

def mock_get_events(file_name)
  Kubeclient::Client.any_instance.stubs(:public_send).with("get_events", {:as=>:raw})
    .returns(File.read(test_resource(file_name)))
end

def mock_get_config_map
  response = JSON.parse(File.read(test_resource('api_get_configmap_rv.json')))
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("get_config_map", "fluentd-config-resource-version", "sumologic").returns(Kubeclient::Resource.new(response))
end

def mock_watch_events(file_name)
  text = File.read(test_resource(file_name))
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("watch_events", {:as=>:raw, :field_selector=>nil, :label_selector=>nil, :namespace=>nil, :resource_version=>nil, :timeout_seconds=>360})
    .returns(text.split(/\n+/))
end

def mock_watch_services
  text = File.read(test_resource('api_watch_services_v1.txt'))
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("watch_services", {:as=>:raw, :field_selector=>nil, :label_selector=>nil, :namespace=>nil, :resource_version=>nil, :timeout_seconds=>360})
    .returns(text.split(/\n+/))
end

def mock_patch_config_map(rv)
  text = File.read(test_resource('api_get_configmap_rv.json'))
  object = JSON.parse(text)
  object['data'] = {"resource-version-events": rv.to_s}
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("patch_config_map", "fluentd-config-resource-version", 
    {data: { "resource-version-events": rv.to_s}}, 'sumologic')
    .returns(object.to_json)
end

def mock_create_config_map_execution(configmap)
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("create_config_map", configmap)
    .raises(StandardError.new 'Error occurred when creating config map.')
end

def mock_patch_config_map_exception(rv)
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("patch_config_map", "fluentd-config-resource-version",
    {data: { "resource-version-events": rv.to_s}}, 'sumologic')
    .raises(StandardError.new 'Error occurred when patching config map.')
end

def mock_get_config_map_exception
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("get_config_map", "fluentd-config-resource-version", "sumologic")
    .raises(StandardError.new 'Error occurred when getting config map.')
end

def mock_get_events_exception
  Kubeclient::Client.any_instance.stubs(:public_send).with("get_events", {:as=>:raw})
    .raises(StandardError.new 'Error occurred when getting events.')
end

def mock_watch_events_exception
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("watch_events", {:as=>:raw, :field_selector=>nil, :label_selector=>nil, :namespace=>nil, :resource_version=>nil, :timeout_seconds=>360})
    .raises(StandardError.new 'Error occurred when watching events.')
end

def get_watch_resources_count_by_type_selector(type_selector, file_name)
  text = File.read(test_resource(file_name))
  objects = text.split(/\n+/).map {|line| JSON.parse(line)}
  objects.select {|object| type_selector.any? {|type| type.casecmp?(object['type'])}}.count
end

def init_globals
  @kubernetes_url = 'http://localhost:8080'
  @verify_ssl = false
  @ca_file = nil
  @client_cert = nil
  @client_key = nil
  @ssl_partial_chain = false
  @bearer_token_file = nil
end
