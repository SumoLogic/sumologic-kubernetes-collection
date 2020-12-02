$LOAD_PATH.unshift(File.expand_path('../../', __FILE__))
require 'test-unit'
require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/test/helpers'
require 'webmock/test_unit'
require 'kubeclient'

Test::Unit::TestCase.include(Fluent::Test::Helpers)
Test::Unit::TestCase.extend(Fluent::Test::Helpers)

def test_resource(name)
  File.new("test/resources/#{name}")
end

def stub_apis
  init_globals
  stub_request(:any, %r{/api$})
    .to_return(
      'body' => {
        'versions' => ['v1']
      }.to_json
    )
  stub_request(:any, %r{/apis$})
    .to_return(
      'body' => {
        'versions' => ['apps/v1', 'extensions/v1beta1']
      }.to_json
    )
  stub_request(:get, %r{/api/v1$})
    .to_return(body: test_resource('api_list_core_v1.json'), status: 200)
  stub_request(:get, %r{/apis/apps$})
    .to_return(body: test_resource('api_list_apps.json'), status: 200)
  stub_request(:get, %r{/apis/extensions$})
    .to_return(body: test_resource('api_list_extensions.json'), status: 200)
  stub_request(:get, %r{/api/v1/endpoints$})
    .to_return(body: test_resource('endpoints_list.json'), status: 200)
  stub_request(:get, %r{/api/v1/namespaces/sumologic/pods})
    .to_return(body: test_resource('pod_sumologic.json'), status: 200)
  stub_request(:get, %r{/apis/extensions/v1beta1/namespaces/sumologic/replicasets})
    .to_return(body: test_resource('rs_sumologic.json'), status: 200)
  stub_request(:get, %r{/apis/extensions/v1beta1/namespaces/sumologic/deployments})
    .to_return(body: test_resource('deploy_sumologic.json'), status: 200)
  stub_request(:get, %r{/api/v1/namespaces/kube-system/pods})
    .to_return(body: test_resource('pod_kube-system.json'), status: 200)
  stub_request(:get, %r{/apis/extensions/v1beta1/namespaces/kube-system/replicasets})
    .to_return(body: test_resource('rs_kube-system.json'), status: 200)
  stub_request(:get, %r{/apis/extensions/v1beta1/namespaces/kube-system/deployments})
    .to_return(body: test_resource('deploy_kube-system.json'), status: 200)
  stub_request(:get, %r{/api/v1/namespaces/non-exist/pods})
    .to_raise(Kubeclient::ResourceNotFoundError.new(404, nil, nil))
  stub_pod_with_nonexistent_owner
end

def stub_pod_with_nonexistent_owner
  stub_request(:get, %r{/api/v1/namespaces/sumologic/pods/pod-with-nonexistent-owner})
    .to_return(body: test_resource('pod_with_nonexistent_owner.json'), status: 200)
  stub_request(:get, %r{/apis/extensions/v1beta1/namespaces/sumologic/replicasets/non-existent-replicaset})
    .to_return(status: 404)
end

def init_globals
  @kubernetes_url = 'http://localhost:8080'
  @verify_ssl = false
  @ca_file = nil
  @client_cert = nil
  @client_key = nil
  @ssl_partial_chain = false
  @bearer_token_file = nil
  @cache_size = 1000
  @cache_ttl = 60 * 60
  @core_api_versions = ['v1']
  @api_groups = ['apps/v1', 'extensions/v1beta1']
end
