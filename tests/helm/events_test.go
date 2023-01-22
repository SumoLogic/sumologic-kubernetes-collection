package helm

import (
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

func TestEventOtelConfigMerge(t *testing.T) {
	t.Parallel()
	templatePath := "templates/events/otelcol/configmap.yaml"
	valuesYaml := `
otelevents:
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

func TestEventOtelConfigOverride(t *testing.T) {
	t.Parallel()
	templatePath := "templates/events/otelcol/configmap.yaml"
	valuesYaml := `
otelevents:
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
