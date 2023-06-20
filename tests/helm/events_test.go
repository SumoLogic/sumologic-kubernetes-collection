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

func TestEventOtlpSource(t *testing.T) {
	t.Parallel()
	templatePath := "templates/events/otelcol/configmap.yaml"
	valuesYaml := `
sumologic:
  events:
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
	require.ElementsMatch(t, []string{"sumologic"}, otelConfig.Service.Pipelines["logs/events"].Exporters)
}
