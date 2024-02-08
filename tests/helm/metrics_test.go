package helm

import (
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

func TestMetadataMetricsOtelConfigMerge(t *testing.T) {
	t.Parallel()
	templatePath := "templates/metrics/otelcol/configmap.yaml"
	valuesYaml := `
metadata:
  metrics:
    config:
      merge:
        processors:
          batch:
            send_batch_size: 7
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Processors struct {
			Batch struct {
				SendBatchSize int `yaml:"send_batch_size"`
			}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, 7, otelConfig.Processors.Batch.SendBatchSize)
}

func TestMetadataMetricsOtelConfigOverride(t *testing.T) {
	t.Parallel()
	templatePath := "templates/metrics/otelcol/configmap.yaml"
	valuesYaml := `
metadata:
  metrics:
    config:
      override:
        key: value
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig map[string]string
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	expected := map[string]string{"key": "value"}
	require.Equal(t, expected, otelConfig)
}

func TestMetadataMetricsOtelConfigExtraProcessors(t *testing.T) {
	t.Parallel()
	templatePath := "templates/metrics/otelcol/configmap.yaml"
	valuesFilePath := path.Join(testDataDirectory, "opentelemetry-metrics-extra-processors.yaml")

	otelConfigTemplate, err := RenderTemplateFromValuesFile(t, valuesFilePath, templatePath)
	require.NoError(t, err)
	otelConfigYaml := GetOtelConfigFromTemplate(t, otelConfigTemplate)

	var otelConfig struct {
		Processors struct {
			Filter struct {
				Metrics struct {
					Include struct {
						MatchType string `yaml:"match_type"`
					}
					Exclude struct {
						MatchType string `yaml:"match_type"`
					}
				}
			} `yaml:"filter/1"`
			RenameMetric struct {
				MetricStatements []struct {
					Context    string   `yaml:"context"`
					Statements []string `yaml:"statements"`
				} `yaml:"metric_statements"`
			} `yaml:"transform/rename_metric"`
			RenameMetadata struct {
				MetricStatements []struct {
					Context    string   `yaml:"context"`
					Statements []string `yaml:"statements"`
				} `yaml:"metric_statements"`
			} `yaml:"transform/rename_metadata"`
		}
		Service struct {
			Pipelines struct {
				Metrics struct {
					Processors []string `yaml:"processors"`
				}
			}
		}
	}

	err = yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, "regexp", otelConfig.Processors.Filter.Metrics.Include.MatchType)
	require.Equal(t, "strict", otelConfig.Processors.Filter.Metrics.Exclude.MatchType)

	renameMetricStatements := []string{
		`set(name, "rrreceiver_mock_metrics_count") where name == "receiver_mock_metrics_count"`,
	}
	require.Equal(t, "metric", otelConfig.Processors.RenameMetric.MetricStatements[0].Context)
	require.Equal(t, renameMetricStatements, otelConfig.Processors.RenameMetric.MetricStatements[0].Statements)

	renameMetadatatatements := []string{
		`set(attributes["k8s.pod.pod_name_new"], attributes["k8s.pod.pod_name"])`,
		`delete_key(attributes, "k8s.pod.pod_name")`,
		`set(attributes["my.static.value"], "<static_value>")`,
	}
	require.Equal(t, "resource", otelConfig.Processors.RenameMetadata.MetricStatements[0].Context)
	require.Equal(t, renameMetadatatatements, otelConfig.Processors.RenameMetadata.MetricStatements[0].Statements)

	expectedPipelineValue := []string{
		"memory_limiter",
		"metricstransform",
		"groupbyattrs",
		"resource",
		"k8s_tagger",
		"source",
		"sumologic",
		"filter/1",
		"transform/rename_metric",
		"transform/rename_metadata",
		"resource/remove_k8s_pod_pod_name",
		"resource/delete_source_metadata",
		"transform/set_name",
		"groupbyattrs/group_by_name",
		"transform/remove_name",
		"filter/drop_unnecessary_metrics",
		"batch",
	}

	require.Equal(t, expectedPipelineValue, otelConfig.Service.Pipelines.Metrics.Processors)
}

func TestMetadataSourceTypeOTLP(t *testing.T) {
	t.Parallel()
	templatePath := "templates/metrics/otelcol/configmap.yaml"

	type OtelConfig struct {
		Exporters struct {
			Default struct {
				MetricFormat string `yaml:"metric_format"`
				Endpoint     string
			} `yaml:"sumologic/default"`
			Rest map[string]interface{} `yaml:",inline"`
		}
		Processors map[string]interface{}
		Service    struct {
			Pipelines struct {
				Metrics struct {
					Processors []string `yaml:"processors"`
					Exporters  []string `yaml:"exporters"`
				}
			}
		}
	}

	var otelConfig OtelConfig
	valuesYaml := `
sumologic:
  metrics:
    sourceType: otlp
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	assert.Equal(t, otelConfig.Exporters.Default.MetricFormat, "otlp")
	assert.Equal(t, otelConfig.Exporters.Default.Endpoint, "${SUMO_ENDPOINT_DEFAULT_OTLP_METRICS_SOURCE}")
	assert.Len(t, otelConfig.Exporters.Rest, 0)
	assert.NotContains(t, otelConfig.Processors, "routing")
	assert.NotContains(t, otelConfig.Service.Pipelines.Metrics.Processors, "routing")
	assert.Equal(t, otelConfig.Service.Pipelines.Metrics.Exporters, []string{"sumologic/default"})
}

func TestMetadataSourceTypeHTTP(t *testing.T) {
	t.Parallel()
	templatePath := "templates/metrics/otelcol/configmap.yaml"

	type OtelConfig struct {
		Exporters map[string]struct {
			MetricFormat string `yaml:"metric_format"`
			Endpoint     string
		} `yaml:"exporters"`
		Processors map[string]interface{}
		Service    struct {
			Pipelines struct {
				Metrics struct {
					Processors []string `yaml:"processors"`
					Exporters  []string `yaml:"exporters"`
				}
			}
		}
	}

	var otelConfig OtelConfig
	valuesYaml := `
sumologic:
  metrics:
    sourceType: http
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Contains(t, otelConfig.Exporters, "sumologic/default")
	defaultExporter := otelConfig.Exporters["sumologic/default"]
	assert.Equal(t, "prometheus", defaultExporter.MetricFormat)
	assert.Equal(t, "${SUMO_ENDPOINT_DEFAULT_METRICS_SOURCE}", defaultExporter.Endpoint)
	assert.Contains(t, otelConfig.Processors, "routing")
	assert.Contains(t, otelConfig.Service.Pipelines.Metrics.Processors, "routing")
	assert.Equal(
		t,
		[]string{
			"sumologic/default",
			"sumologic/apiserver",
			"sumologic/control_plane",
			"sumologic/controller",
			"sumologic/kubelet",
			"sumologic/node",
			"sumologic/scheduler",
			"sumologic/state",
		},
		otelConfig.Service.Pipelines.Metrics.Exporters,
	)
}

func TestNoPrometheusServiceMonitors(t *testing.T) {
	t.Parallel()
	allTemplatePaths := []string{
		"templates/metrics/prometheus/servicemonitors.yaml",
	}

	testCases := []struct {
		Name          string
		ValuesYaml    string
		ExpectedNames []string
		TemplatePaths []string
	}{
		{
			Name: "additionalServiceMonitor",
			ValuesYaml: `
sumologic:
  metrics:
    additionalServiceMonitors:
      - name: collection-sumologic-fluentd-logs-test
        additionalLabels:
          sumologic.com/app: fluentd-logs
        endpoints:
          - port: metrics
        namespaceSelector:
          matchNames:
            - $(NAMESPACE)
        selector:
          matchLabels:
            sumologic.com/app: fluentd-logs
            sumologic.com/scrape: "true"
`,
			ExpectedNames: []string{
				"collection-sumologic-otelcol-logs",
				"collection-sumologic-otelcol-metrics",
				"collection-sumologic-metrics-collector",
				"collection-sumologic-otelcol-logs-collector",
				"collection-sumologic-otelcol-events",
				"collection-sumologic-otelcol-traces",
				"collection-sumologic-prometheus",
				"collection-sumologic-fluentd-logs-test",
			},
			TemplatePaths: allTemplatePaths,
		},
		{
			Name: "onlyAdditionalServiceMonitor",
			ValuesYaml: `
sumologic:
  metrics:
    serviceMonitors: []
    additionalServiceMonitors:
    - name: collection-sumologic-fluentd-logs-test
      additionalLabels:
        sumologic.com/app: fluentd-logs
      endpoints:
        - port: metrics
      namespaceSelector:
        matchNames:
          - $(NAMESPACE)
      selector:
        matchLabels:
          sumologic.com/app: fluentd-logs
          sumologic.com/scrape: "true"
`,
			ExpectedNames: []string{
				"collection-sumologic-fluentd-logs-test",
			},
			TemplatePaths: allTemplatePaths,
		},
		{
			Name:       "default",
			ValuesYaml: "",
			ExpectedNames: []string{
				"collection-sumologic-otelcol-logs",
				"collection-sumologic-otelcol-metrics",
				"collection-sumologic-metrics-collector",
				"collection-sumologic-otelcol-logs-collector",
				"collection-sumologic-otelcol-events",
				"collection-sumologic-otelcol-traces",
				"collection-sumologic-prometheus",
			},
			TemplatePaths: allTemplatePaths,
		},
	}

	for _, tt := range testCases {
		t.Run(tt.Name, func(t *testing.T) {
			names := []string{}
			for _, templatePath := range tt.TemplatePaths {
				servicemonitors := GetServiceMonitors(t, tt.ValuesYaml, templatePath)
				for _, sm := range servicemonitors {
					names = append(names, sm.Name)
				}
			}

			assert.Equal(t, tt.ExpectedNames, names)
		})
	}
}

func TestMetricsCollectionMonitoring(t *testing.T) {
	t.Parallel()
	templatePath := "templates/metrics/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  collectionMonitoring: false
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Processors struct {
			Source struct {
				Exclude struct {
					K8sNamespaceName string `yaml:"k8s.namespace.name"`
				}
			}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, "sumologic", otelConfig.Processors.Source.Exclude.K8sNamespaceName)
}

func TestMetricsExcludeNamespaceRegex(t *testing.T) {
	t.Parallel()
	templatePath := "templates/metrics/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  metrics:
    excludeNamespaceRegex: my_metrics_namespace
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Processors struct {
			Source struct {
				Exclude struct {
					K8sNamespaceName string `yaml:"k8s.namespace.name"`
				}
			}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, "my_metrics_namespace", otelConfig.Processors.Source.Exclude.K8sNamespaceName)
}

func TestMetricsExcludeNamespaceRegexWithCollectionMonitoring(t *testing.T) {
	t.Parallel()
	templatePath := "templates/metrics/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  collectionMonitoring: false
  metrics:
    excludeNamespaceRegex: my_metrics_namespace
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Processors struct {
			Source struct {
				Exclude struct {
					K8sNamespaceName string `yaml:"k8s.namespace.name"`
				}
			}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, "sumologic|my_metrics_namespace", otelConfig.Processors.Source.Exclude.K8sNamespaceName)
}
