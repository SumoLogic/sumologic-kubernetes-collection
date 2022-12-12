package helm

import (
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
