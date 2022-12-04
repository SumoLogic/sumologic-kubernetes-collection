package helm

import (
	"fmt"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/require"

	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

func TestAllTemplates(t *testing.T) {
	var templateDirectories []string
	var err error

	chartVersion, err := GetChartVersion()
	require.NoError(t, err)

	// get the template directories
	dirEntries, err := os.ReadDir(".")
	require.NoError(t, err)
	for _, dirEntry := range dirEntries {
		if dirEntry.IsDir() {
			templateDirectories = append(templateDirectories, dirEntry.Name())
		}
	}

	setupDependencies(t)
	for _, templateDir := range templateDirectories {
		// get template path from config script
		configPath := path.Join(templateDir, configFileName)
		templatePath, err := getTemplatePathFromConfigScript(configPath)
		require.NoError(t, err)
		yamlDirectoryPath := path.Join(templateDir, yamlDirectory)

		// get the input file names
		inputFileNames, err := filepath.Glob(path.Join(yamlDirectoryPath, "*.input.yaml"))
		require.NoError(t, err)
		require.NotEmpty(t, inputFileNames)
		for _, inputFileName := range inputFileNames { // for each input file name, run the test
			inputFileName := inputFileName
			outputFileName := strings.TrimSuffix(inputFileName, ".input.yaml") + ".output.yaml"
			t.Run(inputFileName, func(t *testing.T) {
				t.Parallel()
				runTemplateTest(t, templatePath, inputFileName, outputFileName, chartVersion)
			})
		}
	}
}

// runTemplateTest renders the template using the given values file and compares it to the contents
// of the output file
func runTemplateTest(t *testing.T, templatePath string, valuesFileName string, outputFileName string, chartVersion string) {
	renderedYamlString := RenderTemplate(
		t,
		&helm.Options{
			ValuesFiles: []string{valuesFileName},
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

	// render the actual and expected yaml strings and fix them up
	renderedYamlString = fixupRenderedYaml(renderedYamlString, chartVersion)
	expectedYamlBytes, err := os.ReadFile(outputFileName)
	expectedYamlString := string(expectedYamlBytes)
	expectedYamlString = fixupExpectedYaml(expectedYamlString)
	require.NoError(t, err)

	var expected, rendered unstructured.Unstructured
	helm.UnmarshalK8SYaml(t, expectedYamlString, &expected)
	require.NoError(t, err)
	helm.UnmarshalK8SYaml(t, renderedYamlString, &rendered)
	require.NoError(t, err)

	require.Equal(t, expected, rendered)
}

// setupDependencies adds the repos for chart dependencies and then updates them
// ideally this should be run once per test execution on a fresh machine
func setupDependencies(t *testing.T) {
	repos := map[string]string{
		"fluent":          "https://fluent.github.io/helm-charts",
		"prometheus":      "https://prometheus-community.github.io/helm-charts",
		"falco":           "https://falcosecurity.github.io/charts",
		"bitnami":         "https://charts.bitnami.com/bitnami",
		"influxdata":      "https://helm.influxdata.com/",
		"tailing-sidecar": "https://sumologic.github.io/tailing-sidecar",
		"opentelemetry":   "https://open-telemetry.github.io/opentelemetry-helm-charts",
	}
	for name, url := range repos {
		helm.AddRepo(t, &helm.Options{}, name, url)
	}
	output, err := helm.RunHelmCommandAndGetOutputE(t, &helm.Options{}, "dependency", "update", chartDirectory)
	require.NoError(t, err, output)
}

// getTemplatePathFromConfigScript extracts the template path from a config.sh script that
// the previous test framework used to set the template for the test
func getTemplatePathFromConfigScript(configPath string) (string, error) {
	configScript, err := os.ReadFile(configPath)
	if err != nil {
		return "", err
	}
	regex := regexp.MustCompile("TEST_TEMPLATE=\"([^)]+)\"")
	matches := regex.FindStringSubmatch(string(configScript))
	if len(matches) != 2 {
		return "", fmt.Errorf("expected to get one match, got %v", matches)
	}
	return matches[1], nil
}

// fixupRenderedYaml replaces certain highly variable properties with fixed ones used in the
// expected templates
func fixupRenderedYaml(yaml string, chartVersion string) string {
	checksumRegex := regexp.MustCompile("checksum/config: [a-z0-9]{64}")
	output := yaml
	output = strings.ReplaceAll(output, releaseName, "RELEASE-NAME")
	output = strings.ReplaceAll(output, chartVersion, "%CURRENT_CHART_VERSION%")
	output = checksumRegex.ReplaceAllLiteralString(output, "checksum/config: '%CONFIG_CHECKSUM%'")
	output = strings.TrimSuffix(output, "\n")
	return output
}

// fixupExpectedYaml removes some unnecessary newlines from the expected templates
func fixupExpectedYaml(yaml string) string {
	output := strings.TrimSuffix(yaml, "\n")
	return output
}
