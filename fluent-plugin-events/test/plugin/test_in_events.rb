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
    coreClients = core_clients
    groupClients = group_clients
    print "HAHA clients #{@clients}, clients type #{@clients.class}\n"
    print "core_clients #{coreClients}, core_clients typep #{coreClients.class}\n"
    print "group_clients #{groupClients}, group_clietns type #{groupClients.class}\n"
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
    driver.instance_variable_set(:@clients, @clients)

    mock_get_events('api_list_events_v1.json')
    resource_version = driver.pull_resource_version
    assert_equal '2346293', resource_version
  end

  test 'pull_resource_version correctly from eventlist with v1beta1 api version' do
    config = %([
      api_version "events.k8s.io/v1beta1"
    ])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@clients, @clients)

    mock_get_events('api_list_events_v1beta1.json')
    resource_version = driver.pull_resource_version
    assert_equal '2721303', resource_version
  end

  test 'initialize_resource_version correctly for different resources' do
    config = %([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@clients, @clients)

    mock_get_config_map
    resource = driver.initialize_resource_version
    assert_equal 'dummy-events-rv', resource.data['resource-version-events']
    assert_equal 'dummy-pods-rv', resource.data['resource-version-pods']
    assert_equal 'dummy-services-rv', resource.data['resource-version-services']
  end

  test 'initialize_resource_verion correctly for different client' do
    config = %([
      api_version "events.k8s.io/v1beta1"
    ])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@clients, @clients)

    mock_get_config_map
    resource = driver.initialize_resource_version
    assert_equal 'dummy-events-rv', resource.data['resource-version-events']
    assert_equal 'dummy-pods-rv', resource.data['resource-version-pods']
    assert_equal 'dummy-services-rv', resource.data['resource-version-services']
  end

  test 'watch_events with default type_selector' do
    config = %([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@clients, @clients)
    mock_watch_events('api_watch_events_v1.txt')

    selected_events_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED"],
      'api_watch_events_v1.txt')
    driver.router.expects(:emit).times(selected_events_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 2
    assert_equal 9, events.length
    assert_equal 6, selected_events_count
  end


  test 'watch_events with customer defined type_selector' do
    config = %([
      type_selector ["ADDED", "MODIFIED", "DELETED"]
    ])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@clients, @clients)
    mock_watch_events('api_watch_events_v1.txt')

    selected_events_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED", "DELETED"],
      'api_watch_events_v1.txt')
    driver.router.expects(:emit).times(selected_events_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 2
    assert_equal 9, events.length
    assert_equal 9, selected_events_count
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
    driver.instance_variable_set(:@clients, @clients)
    mock_watch_services

    selected_services_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED"],
      'api_watch_services_v1.txt')
    driver.router.expects(:emit).times(selected_services_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 2
    assert_equal 5, events.length
    assert_equal 4, selected_services_count
  end

  test 'watch events correctly with v1beta1 api version' do
    config = %([
      api_version "events.k8s.io/v1beta1"
    ])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@clients, @clients)
    mock_watch_events('api_watch_events_v1beta1.txt')

    selected_events_count = get_watch_resources_count_by_type_selector(["ADDED", "MODIFIED"],
      'api_watch_events_v1beta1.txt')
    driver.router.expects(:emit).times(selected_events_count).with(anything, anything, anything)
    events = driver.start_watcher_thread
    sleep 2
    assert_equal 8, events.length
    assert_equal 7, selected_events_count
  end

  test 'no events are ingested with too old resource version error' do
    config = %([])
    driver = create_driver(config).instance
    driver.instance_variable_set(:@clients, @clients)
    driver.instance_variable_set(:@last_recreated, 0)

    mock_get_events('api_list_events_v1.json')
    mock_patch_config_map(2346293)
    mock_watch_events('api_watch_events_error_v1.txt')
    driver.router.expects(:emit).never.with(anything, anything, anything)
    
    driver.start_monitor
  end
end
