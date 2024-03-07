package helm

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"
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

	require.ElementsMatch(t, []string{"sumologic"}, keys(otelConfig.Exporters))
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

func TestMetadataLogFormatHTTP(t *testing.T) {
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
    sourceType: http
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

func TestMetadataLogFormatOTLP(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"

	type OtelConfig struct {
		Exporters struct {
			SumoLogic struct {
				LogFormat string `yaml:"log_format"`
				JsonLogs  struct {
					FlattenBody bool `yaml:"flatten_body"`
				} `yaml:"json_logs"`
			} `yaml:"sumologic"`
		}
		Processors map[string]interface{}
		Service    struct {
			Pipelines map[string]struct {
				Receivers  []string
				Processors []string
				Exporters  []string
			}
		}
	}

	testCases := []struct {
		logFormat                 string
		expectedExporterLogFormat string
		expectedProcessors        []string
	}{
		{
			logFormat:                 "json",
			expectedExporterLogFormat: "otlp",
			expectedProcessors:        []string{"transform/add_timestamp"},
		},
		{
			logFormat:                 "fields",
			expectedExporterLogFormat: "otlp",
			expectedProcessors:        []string{"transform/add_timestamp"},
		},
		{
			logFormat:                 "json_merge",
			expectedExporterLogFormat: "otlp",
			expectedProcessors:        []string{"transform/add_timestamp", "transform/flatten"},
		},
		{
			logFormat:                 "text",
			expectedExporterLogFormat: "otlp",
			expectedProcessors:        []string{"transform/add_timestamp", "transform/remove_attributes"},
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
    sourceType: otlp
`
			valuesYaml := fmt.Sprintf(valuesYamlTemplate, testCase.logFormat)
			otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)
			err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
			require.NoError(t, err)
			require.Equal(t, testCase.expectedExporterLogFormat, otelConfig.Exporters.SumoLogic.LogFormat)
			require.Subset(t, otelConfig.Service.Pipelines["logs/otlp/containers"].Processors, testCase.expectedProcessors)
		})
	}
}

func TestMetadataLogOtlpSource(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    sourceType: otlp
`

	var otelConfig struct {
		Exporters  map[string]map[string]interface{}
		Processors map[string]interface{}
		Service    struct {
			Pipelines map[string]struct {
				Receivers  []string
				Processors []string
				Exporters  []string
			}
		}
	}

	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)
	require.ElementsMatch(t, []string{"sumologic"}, keys(otelConfig.Exporters))
	require.Equal(t, "otlp", otelConfig.Exporters["sumologic"]["log_format"])
	require.ElementsMatch(t, []string{"sumologic"}, otelConfig.Service.Pipelines["logs/otlp/containers"].Exporters)
	require.ElementsMatch(t, []string{"sumologic"}, otelConfig.Service.Pipelines["logs/otlp/systemd"].Exporters)
	require.ElementsMatch(t, []string{"sumologic"}, otelConfig.Service.Pipelines["logs/otlp/kubelet"].Exporters)
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

func TestCollectorOtelConfigNoDockerShim(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/collector/otelcol/configmap.yaml"
	renderedYamlString := RenderTemplate(
		t,
		&helm.Options{
			ValuesFiles: []string{},
			SetStrValues: map[string]string{
				"sumologic.accessId":  "accessId",
				"sumologic.accessKey": "accessKey",
			},
			Logger: logger.Discard, // the log output is noisy and doesn't help much
		},
		chartDirectory,
		releaseName,
		[]string{templatePath},
		true,
		"--namespace",
		defaultNamespace,
		"--kube-version",
		"1.24.3",
	)
	otelConfigYaml := GetOtelConfigFromTemplate(t, renderedYamlString)

	var otelConfig struct {
		Receivers struct {
			Filelog struct {
				FingerprintSize string `yaml:"fingerprint_size"`
			} `yaml:"filelog/containers"`
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)
	require.Empty(t, otelConfig.Receivers.Filelog.FingerprintSize)
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

func TestKeepTimeAttribute(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/collector/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    container:
      keep_time_attribute: true
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

	keepTimeOperatorFound := false
	for _, operator := range otelConfig.Receivers.Filelog.Operators {
		if operator.Id == "move-time-attribute" {
			keepTimeOperatorFound = true
			break
		}
	}
	require.True(t, keepTimeOperatorFound)
}

func TestLogsCollectionMonitoring(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  collectionMonitoring: false
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Processors struct {
			SourceContainers struct {
				Exclude struct {
					Namespace string
				}
			} `yaml:"source/containers"`
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, "sumologic", otelConfig.Processors.SourceContainers.Exclude.Namespace)
}

func TestLogsExcludeNamespaceRegex(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  logs:
    container:
      excludeNamespaceRegex: my_logs_namespace
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Processors struct {
			SourceContainers struct {
				Exclude struct {
					Namespace string
				}
			} `yaml:"source/containers"`
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, "my_logs_namespace", otelConfig.Processors.SourceContainers.Exclude.Namespace)
}

func TestLogsExcludeNamespaceRegexWithCollectionMonitoring(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  collectionMonitoring: false
  logs:
    container:
      excludeNamespaceRegex: my_logs_namespace
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Processors struct {
			SourceContainers struct {
				Exclude struct {
					Namespace string
				}
			} `yaml:"source/containers"`
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, "sumologic|my_logs_namespace", otelConfig.Processors.SourceContainers.Exclude.Namespace)
}

func TestCollectorDaemonsetUpdateStrategy(t *testing.T) {
	t.Parallel()

	valuesYaml := `
otellogs:
  daemonset:
    updateStrategy:
      rollingUpdate:
        maxUnavailable: 50%
`
	templatePath := "templates/logs/collector/otelcol/daemonset.yaml"

	renderedTemplate, err := RenderTemplateFromValuesStringE(t, valuesYaml, templatePath)
	require.NoError(t, err)

	var logsCollectorDaemonset struct {
		Spec struct {
			UpdateStrategy struct {
				RollingUpdate struct {
					MaxUnavailable string `yaml:"maxUnavailable"`
				} `yaml:"rollingUpdate"`
			} `yaml:"updateStrategy"`
		}
	}
	err = yaml.Unmarshal([]byte(renderedTemplate), &logsCollectorDaemonset)
	require.NoError(t, err)

	require.Equal(t, "50%", logsCollectorDaemonset.Spec.UpdateStrategy.RollingUpdate.MaxUnavailable)
}
