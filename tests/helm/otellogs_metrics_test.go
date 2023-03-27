package helm

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestOtellogsMetricsDisabled(t *testing.T) {
	t.Parallel()
	templatePath := "templates/logs/collector/otelcol/service.yaml"
	valuesYaml := `
otellogs:
  metrics:
    enabled: false
`
	_, err := RenderTemplateFromValuesStringE(t, valuesYaml, templatePath)
	expectedError := "Error: could not find template templates/logs/collector/otelcol/service.yaml in chart"
	assert.ErrorContains(t, err, expectedError)
}
