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
        source:
          source_category_prefix: "prefix"
`
	otelConfigYaml := GetOtelConfigYaml(t, valuesYaml, templatePath)

	var otelConfig struct {
		Processors struct {
			Source struct {
				SourceCategoryPrefix string `yaml:"source_category_prefix"`
			}
		}
	}
	err := yaml.Unmarshal([]byte(otelConfigYaml), &otelConfig)
	require.NoError(t, err)

	require.Equal(t, "prefix", otelConfig.Processors.Source.SourceCategoryPrefix)
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
