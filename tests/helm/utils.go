package helm

import (
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/go-commons/collections"
	"github.com/gruntwork-io/go-commons/errors"
	"github.com/gruntwork-io/go-commons/files"
	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"
	prometheus "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	corev1 "k8s.io/api/core/v1"
)

// get the chart version from Chart.yaml
func GetChartVersion() (string, error) {
	output, err := os.ReadFile(path.Join(chartDirectory, "Chart.yaml"))
	if err != nil {
		return "", err
	}
	var chartInfo struct {
		Version string `yaml:"version"`
	}
	err = yaml.Unmarshal(output, &chartInfo)
	if err != nil {
		return "", err
	}
	return chartInfo.Version, nil
}

// get the slice of keys for a map
func keys[K comparable, V any](m map[K]V) []K {
	keys := make([]K, len(m))
	i := 0
	for key := range m {
		keys[i] = key
		i++
	}
	return keys
}

// GetOtelConfigYaml renders the given template using a values string, assumes it's an
// otel ConfigMap, and returns the otel configuration as a yaml string
func GetOtelConfigYaml(t *testing.T, valuesYaml string, templatePath string) string {
	renderedYamlString := RenderTemplateFromValuesString(t, valuesYaml, templatePath)
	return GetOtelConfigFromTemplate(t, renderedYamlString)
}

// GetOtelConfigFromTemplate takes otel ConfigMap template content
// and returns the otel configuration as a yaml string
func GetOtelConfigFromTemplate(t *testing.T, templateContent string) string {
	var configMap corev1.ConfigMap
	helm.UnmarshalK8SYaml(t, templateContent, &configMap)
	require.Contains(t, configMap.Data, otelConfigFileName)
	otelConfigYaml := configMap.Data[otelConfigFileName]
	return otelConfigYaml
}

// GetServiceMonitors returns serviceMonitors list from the given templatePath
// In case of error it returns empty list
func GetServiceMonitors(t *testing.T, valuesYaml string, templatePath string) []*prometheus.ServiceMonitor {
	renderedYamlString, err := RenderTemplateFromValuesStringE(t, valuesYaml, templatePath)
	if err != nil {
		return []*prometheus.ServiceMonitor{}
	}

	var list prometheus.ServiceMonitorList
	helm.UnmarshalK8SYaml(t, renderedYamlString, &list)
	return list.Items
}

// UnmarshalMultipleFromYaml can unmarshal multiple objects of the same type from a yaml string
// containing multiple documents, separated by ---
func UnmarshalMultipleFromYaml[T any](t *testing.T, yamlDocs string) []T {
	yamlDocuments, err := SplitYaml(yamlDocs)
	require.NoError(t, err)
	renderedObjects := make([]T, len(yamlDocuments))
	for i, yamlDoc := range yamlDocuments {
		helm.UnmarshalK8SYaml(t, yamlDoc, &renderedObjects[i])
	}
	return renderedObjects
}

// SplitYaml splits a yaml string containing multiple yaml documents into strings
// containing one document each
func SplitYaml(yamlDocs string) ([]string, error) {
	decoder := yaml.NewDecoder(strings.NewReader(yamlDocs))

	var docs []string
	for {
		var value interface{}
		err := decoder.Decode(&value)
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		if value == nil { // skip empty documents
			continue
		}
		valueBytes, err := yaml.Marshal(value)
		if err != nil {
			return nil, err
		}
		docs = append(docs, string(valueBytes))
	}
	return docs, nil
}

// RenderTemplateFromValuesString renders a template based on its path and a values string
// it uses package defaults for other parameters. This function will fail
// the test if there is an error rendering the template.
func RenderTemplateFromValuesString(t *testing.T, valuesYaml string, templatePath string) string {
	renderedYamlString, err := RenderTemplateFromValuesStringE(t, valuesYaml, templatePath)
	require.NoError(t, err)
	return renderedYamlString
}

// RenderTemplateFromValuesStringE renders a template based on its path and a values string
// it uses package defaults for other parameters.
func RenderTemplateFromValuesStringE(t *testing.T, valuesYaml string, templatePath string) (string, error) {
	valuesFile, err := os.CreateTemp(t.TempDir(), "values.yaml")
	require.NoError(t, err)
	_, err = valuesFile.WriteString(valuesYaml)
	require.NoError(t, err)
	return RenderTemplateFromValuesFile(t, valuesFile.Name(), templatePath)
}

// RenderTemplateFromValuesYaml renders a template based on its path and a values file
// it uses package defaults for other parameters.
func RenderTemplateFromValuesFile(t *testing.T, valuesYaml string, templatePath string) (string, error) {
	return RenderTemplateE(
		t,
		&helm.Options{
			ValuesFiles: []string{valuesYaml},
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
	)
}

// requireConfigMapsEqual compares two ConfigMaps in a way that creates nice diffs for long strings
func requireConfigMapsEqual(t *testing.T, expected corev1.ConfigMap, actual corev1.ConfigMap) {
	require.ElementsMatch(t, keys(expected.Data), keys(actual.Data))
	for name, expectedContent := range expected.Data {
		actualContent := actual.Data[name]
		require.Equal(t, expectedContent, actualContent)
	}
	require.Equal(t, expected, actual)
}

// The functions below are copied from terratest for the sole reason of being able to skip the helm dependency update

// RenderTemplate runs `helm template` to render the template given the provided options and returns stdout/stderr from
// the template command. If you pass in templateFiles, this will only render those templates. This function will fail
// the test if there is an error rendering the template.
func RenderTemplate(t *testing.T, options *helm.Options, chartDir string, releaseName string, templateFiles []string, skipDependencies bool, extraHelmArgs ...string) string {
	out, err := RenderTemplateE(t, options, chartDir, releaseName, templateFiles, skipDependencies, extraHelmArgs...)
	require.NoError(t, err)
	return out
}

// RenderTemplateE runs `helm template` to render the template given the provided options and returns stdout/stderr from
// the template command. If you pass in templateFiles, this will only render those templates.
func RenderTemplateE(t *testing.T, options *helm.Options, chartDir string, releaseName string, templateFiles []string, skipDependencies bool, extraHelmArgs ...string) (string, error) {
	// First, verify the charts dir exists
	absChartDir, err := filepath.Abs(chartDir)
	if err != nil {
		return "", errors.WithStackTrace(err)
	}
	if !files.FileExists(chartDir) {
		return "", errors.WithStackTrace(helm.ChartNotFoundError{Path: chartDir})
	}

	// check chart dependencies
	if !skipDependencies {
		if _, err := helm.RunHelmCommandAndGetOutputE(t, &helm.Options{}, "dependency", "build", chartDir); err != nil {
			return "", errors.WithStackTrace(err)
		}
	}

	// Now construct the args
	// We first construct the template args
	args := []string{}
	if options.KubectlOptions != nil && options.KubectlOptions.Namespace != "" {
		args = append(args, "--namespace", options.KubectlOptions.Namespace)
	}
	args, err = getValuesArgsE(t, options, args...)
	if err != nil {
		return "", err
	}
	for _, templateFile := range templateFiles {
		// validate this is a valid template file
		absTemplateFile := filepath.Join(absChartDir, templateFile)
		if !strings.HasPrefix(templateFile, "charts") && !files.FileExists(absTemplateFile) {
			return "", errors.WithStackTrace(helm.TemplateFileNotFoundError{Path: templateFile, ChartDir: absChartDir})
		}

		// Note: we only get the abs template file path to check it actually exists, but the `helm template` command
		// expects the relative path from the chart.
		args = append(args, "--show-only", templateFile)
	}
	// deal extraHelmArgs
	args = append(args, extraHelmArgs...)

	// ... and add the name and chart at the end as the command expects
	args = append(args, releaseName, chartDir)

	// Finally, call out to helm template command
	return helm.RunHelmCommandAndGetStdOutE(t, options, "template", args...)
}

// getValuesArgsE computes the args to pass in for setting values
func getValuesArgsE(t *testing.T, options *helm.Options, args ...string) ([]string, error) {
	args = append(args, formatSetValuesAsArgs(options.SetValues, "--set")...)
	args = append(args, formatSetValuesAsArgs(options.SetStrValues, "--set-string")...)

	valuesFilesArgs, err := formatValuesFilesAsArgsE(t, options.ValuesFiles)
	if err != nil {
		return args, errors.WithStackTrace(err)
	}
	args = append(args, valuesFilesArgs...)

	setFilesArgs, err := formatSetFilesAsArgsE(t, options.SetFiles)
	if err != nil {
		return args, errors.WithStackTrace(err)
	}
	args = append(args, setFilesArgs...)
	return args, nil
}

// formatSetValuesAsArgs formats the given values as command line args for helm using the given flag (e.g flags of
// the format "--set"/"--set-string" resulting in args like --set/set-string key=value...)
func formatSetValuesAsArgs(setValues map[string]string, flag string) []string {
	args := []string{}

	// To make it easier to test, go through the keys in sorted order
	keys := collections.Keys(setValues)
	for _, key := range keys {
		value := setValues[key]
		argValue := fmt.Sprintf("%s=%s", key, value)
		args = append(args, flag, argValue)
	}

	return args
}

// formatValuesFilesAsArgsE formats the given list of values file paths as command line args for helm (e.g of the format
// -f path). This will error if the file does not exist.
func formatValuesFilesAsArgsE(t *testing.T, valuesFiles []string) ([]string, error) {
	args := []string{}

	for _, valuesFilePath := range valuesFiles {
		// Pass through filepath.Abs to clean the path, and then make sure this file exists
		absValuesFilePath, err := filepath.Abs(valuesFilePath)
		if err != nil {
			return args, errors.WithStackTrace(err)
		}
		if !files.FileExists(absValuesFilePath) {
			return args, errors.WithStackTrace(helm.ValuesFileNotFoundError{Path: valuesFilePath})
		}
		args = append(args, "-f", absValuesFilePath)
	}

	return args, nil
}

// formatSetFilesAsArgsE formats the given list of keys and file paths as command line args for helm to set from file
// (e.g of the format --set-file key=path)
func formatSetFilesAsArgsE(t *testing.T, setFiles map[string]string) ([]string, error) {
	args := []string{}

	// To make it easier to test, go through the keys in sorted order
	keys := collections.Keys(setFiles)
	for _, key := range keys {
		setFilePath := setFiles[key]
		// Pass through filepath.Abs to clean the path, and then make sure this file exists
		absSetFilePath, err := filepath.Abs(setFilePath)
		if err != nil {
			return args, errors.WithStackTrace(err)
		}
		if !files.FileExists(absSetFilePath) {
			return args, errors.WithStackTrace(helm.SetFileNotFoundError{Path: setFilePath})
		}
		argValue := fmt.Sprintf("%s=%s", key, absSetFilePath)
		args = append(args, "--set-file", argValue)
	}

	return args, nil
}
