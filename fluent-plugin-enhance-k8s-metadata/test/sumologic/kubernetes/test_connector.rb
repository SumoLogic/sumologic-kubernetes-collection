require 'helper'
require 'sumologic/kubernetes/connector.rb'
require 'fluent/test/log'

class ConnectorTest < Test::Unit::TestCase
  include SumoLogic::Kubernetes::Connector

  def setup
    # runs before each test
    init_globals
  end

  def teardown
    # runs after each test
  end

  def log
    Fluent::Test::TestLogger.new
  end

  test 'ssl_store is expected' do
    store = ssl_store
    assert_not_nil store
  end

  test 'ssl_options is expected' do
    @verify_ssl = true
    @ca_file = 'test/resources/ca.crt'
    @client_cert = nil
    @client_key = nil
    @ssl_partial_chain = true
    options = ssl_options
    assert_not_nil options
    assert_not_nil options[:ca_file]
    assert_not_nil options[:cert_store]
  end

  test 'auth_options is expected' do
    @bearer_token_file = 'test/resources/token'
    options = auth_options
    assert_not_nil options
    assert_not_nil options[:bearer_token]
  end

  test 'connect_kubernetes passed' do
    stub_apis
    connect_kubernetes
  end
end
