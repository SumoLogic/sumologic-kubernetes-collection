require "helper"
require "fluent/plugin/in_events.rb"
require 'fluent/test/driver/input'
require 'fluent/test/log'

class EventsInputTest < Test::Unit::TestCase
  include SumoLogic::Kubernetes::Connector

  def setup
    # runs before each test
    @api_version = 'v1'
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
    mock_watch_events

    selected_events_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED"],
      'api_watch_events_v1.txt')
    driver.router.expects(:emit).times(selected_events_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 5
    assert_equal events.length, 9
    assert_equal selected_events_count, 6
  end


  test 'watch_events with customer defined type_selector' do
    config = %([
      type_selector ["ADDED", "MODIFIED", "DELETED"]
    ])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@client, @client)
    mock_watch_events

    selected_events_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED", "DELETED"],
      'api_watch_events_v1.txt')
    driver.router.expects(:emit).times(selected_events_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 5
    assert_equal events.length, 9
    assert_equal selected_events_count, 9
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
    sleep 5
    assert_equal events.length, 5
    assert_equal selected_services_count, 4
  end
end
