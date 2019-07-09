$LOAD_PATH.unshift(File.expand_path("../../", __FILE__))
require "test-unit"
require "fluent/test"
require "fluent/test/driver/input"
require "fluent/test/helpers"
require 'mocha/test_unit'

Test::Unit::TestCase.include(Fluent::Test::Helpers)
Test::Unit::TestCase.extend(Fluent::Test::Helpers)

def test_resource(name)
  File.new("test/resources/#{name}")
end

def mock_get_events
  Kubeclient::Client.any_instance.stubs(:public_send).with("get_events", {:as=>:raw})
    .returns(File.read(test_resource('api_list_events_v1.json')))
    
end

def mock_get_config_map
  response = JSON.parse(File.read(test_resource('api_get_configmap_rv.json')))
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("get_config_map", "fluentd-config-resource-version", "sumologic").returns(Kubeclient::Resource.new(response))
end

def mock_watch_events
  text = File.read(test_resource('api_watch_events.txt'))
  Kubeclient::Client.any_instance.stubs(:public_send)
    .with("watch_events", {:as=>:raw, :field_selector=>nil, :label_selector=>nil, :namespace=>nil, :resource_version=>nil, :timeout_seconds=>360})
    .returns(text.split(/\n+/))
end

def init_globals
  @kubernetes_url = 'http://localhost:8080'
  @apiVersion = 'v1'
  @verify_ssl = false
  @ca_file = nil
  @client_cert = nil
  @client_key = nil
  @ssl_partial_chain = false
  @bearer_token_file = nil
end