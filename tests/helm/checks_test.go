package helm

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// renderChecksE renders the chart with the given values yaml to trigger checks.txt validation.
// Unlike RenderTemplateFromValuesStringE, it does NOT pre-set sourcelessModeAck or
// migrationDocAcknowledged, so the acknowledgement validation branches can be exercised.
// checks.txt produces no YAML output so we show a simple always-present template instead;
// checks.txt is still fully evaluated (fail calls propagate regardless of --show-only).
func renderChecksE(t *testing.T, valuesYaml string) error {
	t.Helper()
	valuesFile, err := os.CreateTemp(t.TempDir(), "values.yaml")
	require.NoError(t, err)
	_, err = valuesFile.WriteString(valuesYaml)
	require.NoError(t, err)

	_, err = RenderTemplateE(
		t,
		&helm.Options{
			ValuesFiles: []string{valuesFile.Name()},
			SetStrValues: map[string]string{
				"sumologic.accessId":  "accessId",
				"sumologic.accessKey": "accessKey",
			},
			Logger: logger.Discard,
		},
		chartDirectory,
		releaseName,
		[]string{"templates/chart-configmap.yaml"},
		true,
		"--namespace", defaultNamespace,
	)
	return err
}

func TestChecksSourcelessModeAckRequired(t *testing.T) {
	t.Parallel()
	// sourcelessMode: true without sourcelessModeAck must fail
	err := renderChecksE(t, `
sumologic:
  sourcelessMode: true
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`)
	require.Error(t, err)
	assert.ErrorContains(t, err, "sourcelessModeAck")
}

func TestChecksSourcelessModeAckNotRequiredWhenDisabled(t *testing.T) {
	t.Parallel()
	// sourcelessMode: false → no ack required, even without setting sourcelessModeAck
	err := renderChecksE(t, `
sumologic:
  sourcelessMode: false
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`)
	require.NoError(t, err)
}

func TestChecksMigrationDocAckRequired(t *testing.T) {
	t.Parallel()
	// metrics otelcol enabled without migrationDocAcknowledged must fail
	err := renderChecksE(t, `
sumologic:
  sourcelessMode: true
  sourcelessModeAck: true
  metrics:
    collector:
      otelcol:
        enabled: true
        singleLayerPipeline:
          migrationDocAcknowledged: false
`)
	require.Error(t, err)
	assert.ErrorContains(t, err, "migrationDocAcknowledged")
}

func TestChecksBothAcksPresent(t *testing.T) {
	t.Parallel()
	// Both acks set → no error
	err := renderChecksE(t, `
sumologic:
  sourcelessMode: true
  sourcelessModeAck: true
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`)
	require.NoError(t, err)
}

func TestChecksSourcelessModeRequiresSetupOrToken(t *testing.T) {
	t.Parallel()
	// sourcelessMode: true + setupEnabled: false + no installationToken must fail
	err := renderChecksE(t, `
sumologic:
  sourcelessMode: true
  sourcelessModeAck: true
  setupEnabled: false
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`)
	require.Error(t, err)
	assert.ErrorContains(t, err, "setupEnabled")
	assert.ErrorContains(t, err, "installationToken")
}

func TestChecksSourcelessModeWithInstallationToken(t *testing.T) {
	t.Parallel()
	// sourcelessMode: true + setupEnabled: false + installationToken set → no error
	err := renderChecksE(t, `
sumologic:
  sourcelessMode: true
  sourcelessModeAck: true
  setupEnabled: false
  installationToken: "sometoken"
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`)
	require.NoError(t, err)
}

func TestChecksSourcelessModeBlocksHttpSourceTypes(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name       string
		valuesYaml string
		wantErr    string
	}{
		{
			name: "logs http source",
			valuesYaml: `
sumologic:
  sourcelessMode: true
  sourcelessModeAck: true
  logs:
    sourceType: http
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`,
			wantErr: "logs.sourceType",
		},
		{
			name: "metrics http source",
			valuesYaml: `
sumologic:
  sourcelessMode: true
  sourcelessModeAck: true
  metrics:
    sourceType: http
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`,
			wantErr: "metrics.sourceType",
		},
		{
			name: "events http source",
			valuesYaml: `
sumologic:
  sourcelessMode: true
  sourcelessModeAck: true
  events:
    sourceType: http
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`,
			wantErr: "events.sourceType",
		},
		{
			name: "traces http source",
			valuesYaml: `
sumologic:
  sourcelessMode: true
  sourcelessModeAck: true
  traces:
    sourceType: http
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`,
			wantErr: "traces.sourceType",
		},
	}

	for _, tc := range tests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			err := renderChecksE(t, tc.valuesYaml)
			require.Error(t, err)
			assert.ErrorContains(t, err, tc.wantErr)
		})
	}
}

func TestChecksCleanupHostedCollectorRequiresSourcelessMode(t *testing.T) {
	t.Parallel()
	// cleanupHostedCollector: true without sourcelessMode must fail
	err := renderChecksE(t, `
sumologic:
  sourcelessMode: false
  cleanupHostedCollector: true
  metrics:
    collector:
      otelcol:
        singleLayerPipeline:
          migrationDocAcknowledged: true
`)
	require.Error(t, err)
	assert.ErrorContains(t, err, "cleanupHostedCollector")
}
