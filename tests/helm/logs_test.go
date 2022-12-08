package helm

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	corev1 "k8s.io/api/core/v1"
)

const otelConfigFileName = "config.yaml"

// getOtelConfigYaml renders the given template using a values string, assumes it's an
// otel ConfigMap, and returns the otel configuration as a yaml string
func getOtelConfigYaml(t *testing.T, valuesYaml string, templatePath string) string {
	renderedYamlString := RenderTemplateFromValuesString(t, valuesYaml, templatePath)
	var configMap corev1.ConfigMap
	helm.UnmarshalK8SYaml(t, renderedYamlString, &configMap)
	require.Contains(t, configMap.Data, otelConfigFileName)
	otelConfigYaml := configMap.Data[otelConfigFileName]
	return otelConfigYaml
}

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
	otelConfigYaml := getOtelConfigYaml(t, valuesYaml, templatePath)

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
	otelConfigYaml := getOtelConfigYaml(t, valuesYaml, templatePath)

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
	otelConfigYaml := getOtelConfigYaml(t, valuesYaml, templatePath)

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
	otelConfigYaml := getOtelConfigYaml(t, valuesYaml, templatePath)

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
