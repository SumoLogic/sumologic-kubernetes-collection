require "fluent/test"
require "fluent/test/helpers"
require "fluent/test/driver/filter"
require "fluent/plugin/filter_kubernetes_sumologic"
require "test-unit"
require "webmock/test_unit"

class SumoContainerOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::SumoContainerOutput).configure(conf)
  end

  test "test_empty_config" do
    conf = %{}
    assert_nothing_raised do
      create_driver(conf)
    end
  end

  test "test_default_config" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_default_config_no_labels" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs/54575ccdb9",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_fields_format" do
    conf = %{
	      log_format fields
	    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "fields",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
            :fields => "container_id=5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0,pod_labels_pod-template-hash=1013177865,pod_labels_run=log-format-labs,container=log-format-labs,namespace=default,pod=log-format-labs-54575ccdb9-9d677,pod_id=170af806-c801-11e8-9009-025000000001,host=docker-for-desktop,master_url=https =>//10.96.0.1 =>443/api,namespace_id=e8572415-9596-11e8-b28b-025000000001"
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_fields_namespace_labels" do
    conf = %{
	      log_format fields
	    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "namespace_labels" => {
                "app" => "sumologic"
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "fields",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
            :fields => "container_id=5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0,pod_labels_pod-template-hash=1013177865,pod_labels_run=log-format-labs,namespace_labels_app=sumologic,container=log-format-labs,namespace=default,pod=log-format-labs-54575ccdb9-9d677,pod_id=170af806-c801-11e8-9009-025000000001,host=docker-for-desktop,master_url=https =>//10.96.0.1 =>443/api,namespace_id=e8572415-9596-11e8-b28b-025000000001"
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_fields_format_no_timestamp" do
    conf = %{
	      log_format fields
        add_stream false
	    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "fields",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
            :fields => "container_id=5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0,pod_labels_pod-template-hash=1013177865,pod_labels_run=log-format-labs,container=log-format-labs,namespace=default,pod=log-format-labs-54575ccdb9-9d677,pod_id=170af806-c801-11e8-9009-025000000001,host=docker-for-desktop,master_url=https =>//10.96.0.1 =>443/api,namespace_id=e8572415-9596-11e8-b28b-025000000001"
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_no_k8s_labels" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs/54575ccdb9",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_sourcecategory_prefix" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_add_stream" do
    conf = %{
      add_stream false
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_add_time" do
    conf = %{
      add_time false
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "time" => time,
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_sourcecategory_replace_dash" do
    conf = %{
      source_category_replace_dash -
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log-format-labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_kubernetes_meta" do
    conf = %{
      kubernetes_meta false
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_kubernetes_meta_reduce_via_annotation" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs"
            },
            "annotations" => {
                "sumologic.com/kubernetes_meta_reduce" => "true",
            },
            "host" => "docker-for-desktop",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "host" => "docker-for-desktop",
            "namespace_name" => "default",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_kubernetes_meta_reduce_via_conf" do
    conf = %{
      kubernetes_meta_reduce true
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs"
            },
            "host" => "docker-for-desktop",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "host" => "docker-for-desktop",
            "namespace_name" => "default",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_kubernetes_meta_reduce_via_annotation_and_conf" do
    conf = %{
      kubernetes_meta_reduce false
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs"
            },
            "annotations" => {
                "sumologic.com/kubernetes_meta_reduce" => "true",
            },
            "host" => "docker-for-desktop",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "host" => "docker-for-desktop",
            "namespace_name" => "default",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_log_format_json_merge" do
    conf = %{
      log_format json_merge
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json_merge",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_log_format_text" do
    conf = %{
      log_format text
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "text",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_exclude_pod_regex" do
    conf = %{
      exclude_pod_regex foo
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "false"}}, "message" => "foo"})
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "5679EFGH", "pod_name" => "bar-6554321-a87f", "container_name" => "bar", "labels" => {"app" => "bar"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "true"}}, "message" => "foo"})
    end
    assert_equal(1, d.filtered_records.size)
  end

  test "test_exclude_pod_regex_whitelist" do
    conf = %{
      exclude_pod_regex .*
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "false"}}, "message" => "foo"})
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "5679EFGH", "pod_name" => "bar-6554321-a87f", "container_name" => "bar", "labels" => {"app" => "bar"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "true"}}, "message" => "foo"})
    end
    assert_equal(1, d.filtered_records.size)
  end

  test "test_exclude_container_regex" do
    conf = %{
      exclude_container_regex foo
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "false"}}, "message" => "foo"})
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "5679EFGH", "pod_name" => "bar-6554321-a87f", "container_name" => "bar", "labels" => {"app" => "bar"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "true"}}, "message" => "foo"})
    end
    assert_equal(1, d.filtered_records.size)
  end

  test "test_exclude_container_regex_whitelist" do
    conf = %{
      exclude_container_regex .*
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "false"}}, "message" => "foo"})
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "5679EFGH", "pod_name" => "bar-6554321-a87f", "container_name" => "bar", "labels" => {"app" => "bar"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "true"}}, "message" => "foo"})
    end
    assert_equal(1, d.filtered_records.size)
  end

  test "test_exclude_namespace_regex" do
    conf = %{
      exclude_namespace_regex foo
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "foo", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "false"}}, "message" => "foo"})
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "bar", "pod_id" => "5679EFGH", "pod_name" => "bar-6554321-a87f", "container_name" => "bar", "labels" => {"app" => "bar"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "true"}}, "message" => "foo"})
    end
    assert_equal(1, d.filtered_records.size)
  end

  test "test_exclude_namespace_regex_whitelist" do
    conf = %{
      exclude_namespace_regex .*
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "false"}}, "message" => "foo"})
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "5679EFGH", "pod_name" => "bar-6554321-a87f", "container_name" => "bar", "labels" => {"app" => "bar"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "true"}}, "message" => "foo"})
    end
    assert_equal(1, d.filtered_records.size)
  end

  test "test_exclude_host_regex" do
    conf = %{
      exclude_host_regex foo
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "foo", "annotations" => {"sumologic.com/include" => "false"}}, "message" => "foo"})
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "5679EFGH", "pod_name" => "bar-6554321-a87f", "container_name" => "bar", "labels" => {"app" => "bar"}, "host" => "bar", "annotations" => {"sumologic.com/include" => "true"}}, "message" => "foo"})
    end
    assert_equal(1, d.filtered_records.size)
  end

  test "test_exclude_host_regex_whitelist" do
    conf = %{
      exclude_host_regex .*
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "false"}}, "message" => "foo"})
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "5679EFGH", "pod_name" => "bar-6554321-a87f", "container_name" => "bar", "labels" => {"app" => "bar"}, "host" => "localhost", "annotations" => {"sumologic.com/include" => "true"}}, "message" => "foo"})
    end
    assert_equal(1, d.filtered_records.size)
  end

  test "test_exclude_annotation" do
    conf = %{
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost", "annotations" => {"sumologic.com/exclude" => "true"}}, "message" => "foo"})
    end
    assert_equal(0, d.filtered_records.size)
  end

  test "test_sourcehost_annotation" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "annotations" => {
                "sumologic.com/sourceHost" => "foo",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "annotations" => {
                "sumologic.com/sourceHost" => "foo",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "foo",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_sourcename_annotation" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "annotations" => {
                "sumologic.com/sourceName" => "foo",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "annotations" => {
                "sumologic.com/sourceName" => "foo",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "foo",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_sourcecategory_annotation" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "annotations" => {
                "sumologic.com/sourceCategory" => "foo",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "annotations" => {
                "sumologic.com/sourceCategory" => "foo",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/foo",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_sourcecategory_using_labels" do
    conf = %{
      source_category %{namespace}/%{pod_name}/%{label:run}
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_sourcehost_using_pod_id" do
    conf = %{
      source_host %{pod_id}
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "170af806-c801-11e8-9009-025000000001",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_undefined_labels" do
    conf = %{
      source_category %{namespace}/%{pod_name}/%{label:foo}
    }
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs/undefined",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_exclude_systemd_unit_regex" do
    conf = %{
      exclude_unit_regex .*
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"_SYSTEMD_UNIT" => "test", "kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost"}, "message" => "foo"})
    end
    assert_equal(0, d.filtered_records.size)
  end

  test "test_exclude_systemd_facility_regex" do
    conf = %{
      exclude_facility_regex .*
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"_SYSTEMD_UNIT" => "test", "SYSLOG_FACILITY" => "test", "kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost"}, "message" => "foo"})
    end
    assert_equal(0, d.filtered_records.size)
  end

  test "test_exclude_systemd_priority_regex" do
    conf = %{
      exclude_priority_regex .*
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"_SYSTEMD_UNIT" => "test", "PRIORITY" => "test", "kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost"}, "message" => "foo"})
    end
    assert_equal(0, d.filtered_records.size)
  end

  test "test_exclude_systemd_hostname_regex" do
    conf = %{
      exclude_host_regex .*
    }
    d = create_driver(conf)
    time = @time
    d.run do
      d.feed("filter.test", time, {"_SYSTEMD_UNIT" => "test", "_HOSTNAME" => "test", "kubernetes" => {"namespace_name" => "test", "pod_id" => "1234ABCD", "pod_name" => "foo-1234556-f87a", "container_name" => "foo", "labels" => {"app" => "foo"}, "host" => "localhost"}, "message" => "foo"})
    end
    assert_equal(0, d.filtered_records.size)
  end

  test "test_pre_1.8_dynamic_bit_removal" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-1013177865-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-1013177865-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-1013177865-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_1.8-1.11_dynamic_bit_removal" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "1013177865",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_post_1.11_dynamic_bit_removal" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "54575ccdb9",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-54575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "54575ccdb9",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-54575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end

  test "test_mismatch_dynamic_bit_is_left" do
    conf = %{}
    d = create_driver(conf)
    time = @time
    input = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-53575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "54575ccdb9",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
    }
    d.run do
      d.feed("filter.test", time, input)
    end
    expected = {
        "timestamp" => 1538677347823,
        "log" => "some message",
        "stream" => "stdout",
        "docker" => {
            "container_id" => "5c280b6ad5abec32e9af729295c20f60fbeadf3ba16fda2d121f87228e6822e0",
        },
        "kubernetes" => {
            "container_name" => "log-format-labs",
            "namespace_name" => "default",
            "pod_name" => "log-format-labs-53575ccdb9-9d677",
            "pod_id" => "170af806-c801-11e8-9009-025000000001",
            "labels" => {
                "pod-template-hash" => "54575ccdb9",
                "run" => "log-format-labs",
            },
            "host" => "docker-for-desktop",
            "master_url" => "https =>//10.96.0.1 =>443/api",
            "namespace_id" => "e8572415-9596-11e8-b28b-025000000001",
        },
        "_sumo_metadata" => {
            :category => "kubernetes/default/log/format/labs/53575ccdb9",
            :host => "",
            :log_format => "json",
            :source => "default.log-format-labs-53575ccdb9-9d677.log-format-labs",
        },
    }
    assert_equal(1, d.filtered_records.size)
    assert_equal(d.filtered_records[0], expected)
  end
end