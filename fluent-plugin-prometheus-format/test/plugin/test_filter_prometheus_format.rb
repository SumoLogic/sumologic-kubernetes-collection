require 'helper'
require 'fluent/plugin/filter_prometheus_format.rb'

class PrometheusFormatFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  sub_test_case 'trasform datapoint to prometheus format' do
    test 'transform single data point' do
      config = %([])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'relabel keys' do
      config = %([
        relabel {
          "service" : "prometheus.service",
          "prometheus_replica" : "prometheus.replica"
        }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.relabel'
    end

    test 'ignore keys in relabel but not in record' do
      config = %([
        relabel {
          "service" : "prometheus.service",
          "prometheus_replica" : "prometheus.replica",
          "some_key" : "some_value",
          "foo" : ""
        }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.relabel'
    end

    test 'remove keys if relabel to empty string' do
      config = %([
        relabel { "service" : "", "prometheus_replica" : ""}
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.relabel.remove'
    end
  end

  sub_test_case 'trasform datapoint with nested json' do
    test 'transform single data point' do
      config = %([])
      outputs = filter_datapoints(config, 'datapoint.nested')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.nested'
    end

    test 'relabel keys after flatten' do
      config = %([
        relabel {
          "service" : "",
          "kubernetes_service_name" : "service_name",
          "kubernetes_pod_name" : "pod_name"
        }
      ])
      outputs = filter_datapoints(config, 'datapoint.nested')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.nested.relabel'
    end

    test 'relabel keys with space' do
      config = %([
        relabel {
          "service" : "",
          "kubernetes_service_na e" : "service_na e",
          "kubernetes_pod_na e" : "pod_na e"
        }
      ])
      outputs = filter_datapoints(config, 'datapoint.nested.spaces')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.nested.spaces.relabel'
    end

    test 'transform data point with escaped sequences' do
      config = %([])
      outputs = filter_datapoints(config, 'datapoint.nested.escape')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.nested.escape'
    end
  end

  sub_test_case 'inclusions, non-strict mode' do
    test 'do include point with tag value matching regex' do
      config = %([
        inclusions { "namespace" : "kube-system" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point with tag value not matching regex' do
      config = %([
        inclusions { "namespace" : "cube-system" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do include point without key in inclusions' do
      config = %([
        inclusions { "namespaceX" : "XXX" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do include point with all tags value matching regexs' do
      config = %([
        inclusions { "namespace" : "kube-system", "instance" : "^172.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point with any tag value not matching regex' do
      config = %([
        inclusions { "namespace" : "kube-system", "instance" : "^196.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do include point with tag key not in the record' do
      config = %([
        inclusions { "namespaceX" : "XXXX", "instance" : "^172.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point with existing tag value not matching regex' do
      config = %([
        inclusions { "namespaceX" : "XXXX", "instance" : "^196.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end
  end

  sub_test_case 'inclusions, strict mode' do
    test 'do include point with tag value matching regex' do
      config = %([
        inclusions { "namespace" : "kube-system" }
        strict_inclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point with tag value not matching regex' do
      config = %([
        inclusions { "namespace" : "cube-system" }
        strict_inclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do not include point without key in inclusions' do
      config = %([
        inclusions { "namespaceX" : "XXX" }
        strict_inclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do include point with all tags value matching regexs' do
      config = %([
        inclusions { "namespace" : "kube-system", "instance" : "^172.*" }
        strict_inclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point with any tag value not matching regex' do
      config = %([
        inclusions { "namespace" : "kube-system", "instance" : "^196.*" }
        strict_inclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do not include point with tag key not in the record' do
      config = %([
        inclusions { "namespaceX" : "XXXX", "instance" : "^172.*" }
        strict_inclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do not include point with existing tag value not matching regex' do
      config = %([
        inclusions { "namespaceX" : "XXXX", "instance" : "^196.*" }
        strict_inclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end
  end

  sub_test_case 'exclusions, non-strict mode' do
    test 'do not include point with tag value matching regex' do
      config = %([
        exclusions { "namespace" : "kube-system" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do include point with tag value not matching regex' do
      config = %([
        exclusions { "namespace" : "cube-system" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do include point without key in exclusions' do
      config = %([
        exclusions { "namespaceX" : "XXX" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do include point with all tags value not matching regexs' do
      config = %([
        exclusions { "namespace" : "cube-system", "instance" : "^196.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point with any tag value matching regex' do
      config = %([
        exclusions { "namespace" : "kube-system", "instance" : "^196.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do include point with tag key not in the record' do
      config = %([
        exclusions { "namespaceX" : "XXXX", "instance" : "^196.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point with existing tag value matching regex' do
      config = %([
        exclusions { "namespaceX" : "XXXX", "instance" : "^172.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end
  end

  sub_test_case 'exclusions, strict mode' do
    test 'do not include point with tag value matching regex' do
      config = %([
        exclusions { "namespace" : "kube-system" }
        strict_exclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do include point with tag value not matching regex' do
      config = %([
        exclusions { "namespace" : "cube-system" }
        strict_exclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point without key in exclusions' do
      config = %([
        exclusions { "namespaceX" : "XXX" }
        strict_exclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do include point with all tags value not matching regexs' do
      config = %([
        exclusions { "namespace" : "cube-system", "instance" : "^196.*" }
        strict_exclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint'
    end

    test 'do not include point with any tag value matching regex' do
      config = %([
        exclusions { "namespace" : "kube-system", "instance" : "^196.*" }
        strict_exclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do not include point with tag key not in the record' do
      config = %([
        exclusions { "namespaceX" : "XXXX", "instance" : "^196.*" }
        strict_exclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end

    test 'do not include point with existing tag value matching regex' do
      config = %([
        exclusions { "namespaceX" : "XXXX", "instance" : "^172.*" }
        strict_exclusions true
      ])
      outputs = filter_datapoints(config, 'datapoint')
      assert_equal 0, outputs.length
    end
  end

  sub_test_case 'both inclusions and exclusions are validated' do
    test 'both positive' do
      config = %([
        inclusions { "namespace" : "kube-system" }
        exclusions { "instance" : "^196.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint.nested')
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.nested'
    end

    test 'negative on inclusions' do
      config = %([
        inclusions { "namespace" : "cube-system" }
        exclusions { "instance" : "^196.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint.nested')
      assert_equal 0, outputs.length
    end

    test 'negative on exclusions' do
      config = %([
        inclusions { "namespace" : "kube-system" }
        exclusions { "instance" : "^172.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint.nested')
      assert_equal 0, outputs.length
    end

    test 'both negative' do
      config = %([
        inclusions { "namespace" : "cube-system" }
        exclusions { "instance" : "^172.*" }
      ])
      outputs = filter_datapoints(config, 'datapoint.nested')
      assert_equal 0, outputs.length
    end
  end

  sub_test_case 'validate inclusions after flatten and relabel' do
    test 'positive' do
      config = %([
        relabel {
          "service" : "",
          "kubernetes_service_name" : "service_name",
          "kubernetes_pod_name" : "pod_name"
        }
        inclusions { "pod_name" : "^kube-scheduler-.*" }
      ])
      outputs = filter_datapoints(
        config,
        'datapoint.nested'
      )
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.nested.relabel'
    end

    test 'negative' do
      config = %([
        relabel {
          "service" : "",
          "kubernetes_service_name" : "service_name",
          "kubernetes_pod_name" : "pod_name"
        }
        inclusions { "pod_name" : "^cube-scheduler-.*" }
      ])
      outputs = filter_datapoints(
        config,
        'datapoint.nested'
      )
      assert_equal 0, outputs.length
    end
  end

  sub_test_case 'validate exclusions after flatten and relabel' do
    test 'positive' do
      config = %([
        relabel {
          "service" : "",
          "kubernetes_service_name" : "service_name",
          "kubernetes_pod_name" : "pod_name"
        }
        exclusions { "pod_name" : "^cube-scheduler.*" }
      ])
      outputs = filter_datapoints(
        config,
        'datapoint.nested'
      )
      assert_equal 1, outputs.length
      verify_with_expected outputs, 'output.datapoint.nested.relabel'
    end

    test 'negative' do
      config = %([
        relabel {
          "service" : "",
          "kubernetes_service_name" : "service_name",
          "kubernetes_pod_name" : "pod_name"
        }
        exclusions { "pod_name" : "^kube-scheduler.*" }
      ])
      outputs = filter_datapoints(
        config,
        'datapoint.nested'
      )
      assert_equal 0, outputs.length
    end
  end

  sub_test_case 'combinations' do
    test 'case 1' do
      config = %([
        relabel {
          "service" : "",
          "prometheus_replica" : "",
          "prometheus" : "prometheus.name",
          "pod_name" : "pod.name",
          "pod" : "pod.name"
        }
        inclusions {
          "instance" : "^172\.20\.36.*"
        }
        strict_inclusions true
        exclusions {
          "pod.name" : "^kube.*"
        }
        strict_exclusions true
      ])
      outputs = filter_datapoints(
        config,
        'batch'
      )
      assert_equal 270, outputs.length
      verify_with_expected outputs, 'output.batch.case1'
    end

    test 'case 2' do
      config = %([
        relabel {
          "service" : "",
          "prometheus_replica" : "",
          "prometheus" : "prometheus.name",
          "pod_name" : "pod.name",
          "pod" : "pod.name",
          "le" : ""
        }
        inclusions {
          "job" : "apiserver",
          "verb" : "GET"
        }
        strict_inclusions true
      ])
      outputs = filter_datapoints(
        config,
        'batch'
      )
      assert_equal 52, outputs.length
      verify_with_expected outputs, 'output.batch.case2'
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter
      .new(Fluent::Plugin::PrometheusFormatFilter)
      .configure(conf)
  end

  def filter_datapoints(config, json_name)
    input = JSON.parse!(
      File.read("test/resources/#{json_name}.json")
    )

    d = create_driver(config)
    d.run(default_tag: 'datapoint.input') do
      input['datapoints'].flat_map do |datapoint|
        d.feed(datapoint)
        d.filtered_records
      end
    end
  end

  def verify_with_expected(outputs, expected_json_name)
    expected = JSON.parse!(
      File.read("test/resources/#{expected_json_name}.json")
    )
    assert_equal expected['outputs'], outputs
  end
end
