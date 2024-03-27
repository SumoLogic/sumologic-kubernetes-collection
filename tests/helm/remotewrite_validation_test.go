package helm

import (
	"path"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
)

func TestValidationOfRemoteWriteConfigWithPrometheusDisabled(t *testing.T) {
	valuesFilePath := path.Join(testDataDirectory, "remotewrite", "remotewrites-defined-prometheus-disabled.yaml")
	_, err := RenderTemplateE(
		t,
		&helm.Options{
			ValuesFiles: []string{valuesFilePath},
			SetStrValues: map[string]string{
				"sumologic.accessId":  "accessId",
				"sumologic.accessKey": "accessKey",
			},
			Logger: logger.Discard, // the log output is noisy and doesn't help much
		},
		chartDirectory,
		releaseName,
		[]string{},
		true,
		"--namespace",
		defaultNamespace,
	)
	assert.ErrorContains(t, err, "Remote write definitions are not supported by Otel")
}

func TestValidationOfRemoteWriteConfigWithPrometheusEnabled(t *testing.T) {
	valuesFilePath := path.Join(testDataDirectory, "remotewrite", "remotewrites-defined-prometheus-enabled.yaml")
	template := RenderTemplate(
		t,
		&helm.Options{
			ValuesFiles: []string{valuesFilePath},
			SetStrValues: map[string]string{
				"sumologic.accessId":  "accessId",
				"sumologic.accessKey": "accessKey",
			},
			Logger: logger.Discard, // the log output is noisy and doesn't help much
		},
		chartDirectory,
		releaseName,
		[]string{},
		true,
		"--namespace",
		defaultNamespace,
	)
	assert.NotEmpty(t, template)
}

func TestRemoteWriteValidationWhenMetricsAreDisabled(t *testing.T) {
	valuesFilePath := path.Join(testDataDirectory, "remotewrite", "metrics-disabled.yaml")
	template := RenderTemplate(
		t,
		&helm.Options{
			ValuesFiles: []string{valuesFilePath},
			SetStrValues: map[string]string{
				"sumologic.accessId":  "accessId",
				"sumologic.accessKey": "accessKey",
			},
			Logger: logger.Discard, // the log output is noisy and doesn't help much
		},
		chartDirectory,
		releaseName,
		[]string{},
		true,
		"--namespace",
		defaultNamespace,
	)
	assert.NotEmpty(t, template)
}
