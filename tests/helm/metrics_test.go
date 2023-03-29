package helm

import (
	"path"
	"testing"

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
		"filter/1",
		"transform/rename_metric",
		"transform/rename_metadata",
		"resource/remove_k8s_pod_pod_name",
		"resource/delete_source_metadata",
		"sumologic_schema",
		"batch",
		"routing",
	}

	require.Equal(t, expectedPipelineValue, otelConfig.Service.Pipelines.Metrics.Processors)
}
