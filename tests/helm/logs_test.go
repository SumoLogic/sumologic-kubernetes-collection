package helm

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

func TestMetadataOtelConfigMerge(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
metadata:
  logs:
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

func TestMetadataOtelConfigOverride(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
metadata:
  logs:
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

func TestMetadataOtelConfigFluentBitEnabled(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    collector:
      otelcol:
        enabled: false

fluent-bit:
  enabled: true
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Receivers map[string]interface{}
		Service   struct {
			Pipelines map[string]interface{}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.ElementsMatch(t, []string{"fluentforward"}, keys(otelConfig.Receivers))
	require.ElementsMatch(t, []string{
		"logs/fluent/containers",
		"logs/fluent/kubelet",
		"logs/fluent/systemd",
	}, keys(otelConfig.Service.Pipelines))
}

func TestMetadataOtelConfigSystemdDisabled(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    systemd:
      enabled: false
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Exporters  map[string]interface{}
		Processors map[string]interface{}
		Service    struct {
			Pipelines map[string]interface{}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.ElementsMatch(t, []string{"sumologic/containers"}, keys(otelConfig.Exporters))
	require.ElementsMatch(t, []string{"logs/otlp/containers"}, keys(otelConfig.Service.Pipelines))
	for processorName := range otelConfig.Processors {
		require.NotContains(t, processorName, "systemd")
		require.NotContains(t, processorName, "kubelet")
	}
}

func TestMetadataOtelExtraProcessors(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    container:
      otelcol:
        enabled: true
        extraProcessors:
        - filter/include-host:
            logs:
              include:
                match_type: strict
                resource_attributes:
                - key: host.name
                  value: just_this_one_hostname
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Exporters  map[string]interface{}
		Processors map[string]interface{}
		Service    struct {
			Pipelines map[string]struct {
				Receivers  []string
				Processors []string
				Exporters  []string
			}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Contains(t, otelConfig.Processors, "filter/include-host")

	containersPipeline := otelConfig.Service.Pipelines["logs/otlp/containers"]
	require.Contains(t, containersPipeline.Processors, "filter/include-host")
}

func TestMetadataFluentBitExtraProcessors(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    collector:
      otelcol: 
        enabled: false
    container:
      otelcol:
        extraProcessors:
        - filter/include-host:
            logs:
              include:
                match_type: strict
                resource_attributes:
                - key: host.name
                  value: just_this_one_hostname
fluent-bit:
  enabled: true
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Exporters  map[string]interface{}
		Processors map[string]interface{}
		Service    struct {
			Pipelines map[string]struct {
				Receivers  []string
				Processors []string
				Exporters  []string
			}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Contains(t, otelConfig.Processors, "filter/include-host")

	containersPipeline := otelConfig.Service.Pipelines["logs/fluent/containers"]
	require.Contains(t, containersPipeline.Processors, "filter/include-host")
}

func TestMetadataLogFormat(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"

	type OtelConfig struct {
		Exporters struct {
			Containers struct {
				LogFormat string `yaml:"log_format"`
				JsonLogs  struct {
					FlattenBody bool `yaml:"flatten_body"`
				} `yaml:"json_logs"`
			} `yaml:"sumologic/containers"`
		}
	}

	testCases := []struct {
		logFormat                   string
		expectedExporterLogFormat   string
		expectedExporterFlattenBody bool
	}{
		{
			logFormat:                 "json",
			expectedExporterLogFormat: "json",
		},
		{
			logFormat:                 "fields",
			expectedExporterLogFormat: "json",
		},
		{
			logFormat:                 "json_merge",
			expectedExporterLogFormat: "json",
		},
		{
			logFormat:                 "text",
			expectedExporterLogFormat: "text",
		},
	}

	for _, testCase := range testCases {
		testCase := testCase
		t.Run(testCase.logFormat, func(t *testing.T) {
			t.Parallel()
			var otelConfig OtelConfig
			valuesYamlTemplate := `
sumologic:
  logs:
    container:
      format: %s
`
			valuesYaml := fmt.Sprintf(valuesYamlTemplate, testCase.logFormat)
			otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)
			err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
			require.NoError(t, err)
			require.Equal(t, testCase.expectedExporterLogFormat, otelConfig.Exporters.Containers.LogFormat)
			require.False(t, otelConfig.Exporters.Containers.JsonLogs.FlattenBody)
		})
	}
}

func TestCollectorOtelConfigMerge(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/collector/otelcol/configmap.yaml"
	valuesYaml := `
otellogs:
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

func TestCollectorOtelConfigOverride(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/collector/otelcol/configmap.yaml"
	valuesYaml := `
otellogs:
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

func TestCollectorOtelConfigSystemdDisabled(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/collector/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    systemd:
      enabled: false
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Receivers  map[string]interface{}
		Processors map[string]interface{}
		Service    struct {
			Pipelines map[string]interface{}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.ElementsMatch(t, []string{"filelog/containers"}, keys(otelConfig.Receivers))
	require.ElementsMatch(t, []string{"logs/containers"}, keys(otelConfig.Service.Pipelines))
	for processorName := range otelConfig.Processors {
		require.NotContains(t, processorName, "systemd")
		require.NotContains(t, processorName, "kubelet")
	}
}

func TestCollectorOtelConfigMultilineDisabled(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/collector/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    multiline:
      enabled: false
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Receivers struct {
			Filelog struct {
				Operators []struct {
					Id     string
					Type   string
					Output string
				}
			} `yaml:"filelog/containers"`
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	for _, operator := range otelConfig.Receivers.Filelog.Operators {
		require.NotEqual(t, "merge-multiline-logs", operator.Id)
	}
}

func TestCollectorOtelConfigSystemdUnits(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/collector/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    systemd:
      units:
        - test
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Receivers struct {
			Journald struct {
				Units []string
			}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, []string{"test"}, otelConfig.Receivers.Journald.Units)
}
