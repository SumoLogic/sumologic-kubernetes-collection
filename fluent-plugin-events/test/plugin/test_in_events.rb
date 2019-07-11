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

  test 'pull_resource_version correctly from eventlist' do
    config = %([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)

    mock_get_events
    resource_version = driver.pull_resource_version
    assert_equal resource_version, '2346293'
  end

  test 'initialize_resource_version correctly for different resources' do
    config = %([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)

    mock_get_config_map
    resource = driver.initialize_resource_version
    assert_equal resource.data['resource-version-events'], 'dummy-events-rv'
    assert_equal resource.data['resource-version-pods'], 'dummy-pods-rv'
    assert_equal resource.data['resource-version-services'], 'dummy-services-rv'
  end

  test 'watch_events with default type_selector' do
    config = %([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)
    mock_watch_events('api_watch_events_v1.txt')

    selected_events_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED"],
      'api_watch_events_v1.txt')
    driver.router.expects(:emit).times(selected_events_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 2
    assert_equal events.length, 9
    assert_equal selected_events_count, 6
  end


  test 'watch_events with customer defined type_selector' do
    config = %([
      type_selector ["ADDED", "MODIFIED", "DELETED"]
    ])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)
    mock_watch_events('api_watch_events_v1.txt')

    selected_events_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED", "DELETED"],
      'api_watch_events_v1.txt')
    driver.router.expects(:emit).times(selected_events_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 2
    assert_equal events.length, 9
    assert_equal selected_events_count, 9
  end

  test 'configuration error will be thrown if type_selector is invalid' do
    assert_raise Fluent::ConfigError do 
      create_driver(%([
        type_selector ["ADDED", "MODIFIED", "DELETED", "BOOKED"]
      ]))
    end

    assert_raise Fluent::ConfigError do
      create_driver(%([
        type_selector ["ADDED", "MODIFIED", "INVALIDTYPE"]
      ]))
    end

    assert_raise Fluent::ConfigError do
      create_driver(%([
        type_selector []
      ]))
    end
  end

  test 'watch other resources with default type_selector' do 
    config = %([
      resource_name "services"
    ])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)
    mock_watch_services

    selected_services_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED"],
      'api_watch_services_v1.txt')
    driver.router.expects(:emit).times(selected_services_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 2
    assert_equal events.length, 5
    assert_equal selected_services_count, 4
  end

  test 'no events are ingested with error type and resource_version is set from pull_resource_version' do
    config = %([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)
    driver.instance_variable_set(:@last_recreated, 0)
    new_resource_version = 2346293

    mock_get_events
    mock_patch_config_map(new_resource_version)
    mock_watch_events('api_watch_events_error_v1.txt')
    driver.router.expects(:emit).never.with(anything, anything, anything)
    
    driver.start_monitor
    assert_equal driver.instance_variable_get(:@resource_version), new_resource_version.to_s
  end
end
