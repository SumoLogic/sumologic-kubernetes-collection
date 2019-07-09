require "helper"
require "fluent/plugin/in_events.rb"
require 'fluent/test/driver/input'
require 'fluent/test/log'

class EventsInputTest < Test::Unit::TestCase
  include SumoLogic::Kubernetes::Connector

  def setup
    # runs before each test
    init_globals
    connect_kubernetes
  end

  def teardown
    # runs after each test
  end

  def log
    Fluent::Test::TestLogger.new
  end
  
  def create_driver(conf)
    driver = Fluent::Test::Driver::Input.new(Fluent::Plugin::EventsInput).configure(conf)
  end

  test 'pull resourcze version correctly' do
    config = %([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)
    mock_get_events
    resource_version = driver.pull_resource_version
    assert_equal resource_version, '2346293'
  end

  test 'initailize resource version correctly' do
    config =%([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)
    mock_get_config_map
    resource = driver.initialize_resource_version
    resource_version = resource.data['resource-version']
    assert_equal resource_version, '2361803'
  end

  test 'watch events' do
    config =%([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)
    driver.instance_variable_set(:@emitted_events, 0)
    mock_get_config_map
    mock_get_events
    mock_watch_events

    driver.router.expects(:emit).times(6).with(anything,anything,anything)
    events = driver.start_watcher_thread
    sleep 5
    assert_equal events.count, 9
  end
end