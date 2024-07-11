package helm

import (
	"fmt"
	"os"
	"regexp"
	"strings"
	"testing"

	doublestar "github.com/bmatcuk/doublestar/v4"
	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
)

func TestGoldenFiles(t *testing.T) {
	var err error

	chartVersion, err := GetChartVersion()
	require.NoError(t, err)

	// get the input files
	inputFileNames, err := doublestar.FilepathGlob("testdata/goldenfile/**/*.input.yaml")
	require.NoError(t, err)
	require.NotEmpty(t, inputFileNames)
	for _, inputFileName := range inputFileNames { // for each input file name, run the test
		valuesFileName := inputFileName
		outputFileName := strings.TrimSuffix(valuesFileName, ".input.yaml") + ".output.yaml"
		t.Run(inputFileName, func(t *testing.T) {
			t.Parallel()
			runGoldenFileTest(t, valuesFileName, outputFileName, chartVersion)
		})
	}
}

// runTemplateTest renders the template using the given values file and compares it to the contents
// of the output file
func runGoldenFileTest(t *testing.T, valuesFileName string, outputFileName string, chartVersion string) {
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
		[]string{},
		true,
		"--namespace",
		defaultNamespace,
		"--kube-version",
		defaultK8sVersion,
	)

	// render the actual and expected yaml strings and fix them up
	renderedYamlString = fixupRenderedYaml(renderedYamlString, chartVersion)
	expectedYamlBytes, err := os.ReadFile(outputFileName)
	require.NoError(t, err)
	expectedYamlStrings, err := SplitYaml(string(expectedYamlBytes))
	require.NoError(t, err)

	for _, expectedYamlString := range expectedYamlStrings {
		var expectedObject unstructured.Unstructured
		var renderedObjects []unstructured.Unstructured
		helm.UnmarshalK8SYaml(t, expectedYamlString, &expectedObject)
		require.NoError(t, err)
		renderedObjects = UnmarshalMultipleFromYaml[unstructured.Unstructured](t, renderedYamlString)
		require.NoError(t, err)

		// find the object we expect
		var actualObject *unstructured.Unstructured = nil
		var objectIndex int
		for i, renderedObject := range renderedObjects {
			if renderedObject.GetName() == expectedObject.GetName() &&
				renderedObject.GetKind() == expectedObject.GetKind() {
				actualObject = &renderedObject
				objectIndex = i
				break
			}
		}
		require.NotNilf(t, actualObject, "Couldn't find object %s/%s in output", expectedObject.GetKind(), expectedObject.GetName())

		// regenerate golden file if enabled and the values don't match
		// we intentionally use the Helm output directly here, because it's more human-readable
		regenerateGoldenFiles := os.Getenv("REGENERATE_GOLDENFILES") != ""
		if regenerateGoldenFiles && !assert.Equal(t, expectedObject, *actualObject) {
			yamlDocuments := []string{}
			preYamlDocuments := strings.Split(renderedYamlString, "\n---")
			// Try to parse all documents to eliminate empty ones:
			// - Helm output starts with ---
			// - Output consisting of comments only
			for _, document := range preYamlDocuments {
				var expectedObject unstructured.Unstructured
				if err := helm.UnmarshalK8SYamlE(t, document, &expectedObject); err != nil {
					continue
				}
				yamlDocuments = append(yamlDocuments, document)
			}
			yamlDoc := "---" + yamlDocuments[objectIndex]
			outputFile, err := os.OpenFile(outputFileName, os.O_WRONLY, os.ModePerm)
			require.NoError(t, err)
			err = outputFile.Truncate(0)
			require.NoError(t, err)
			_, err = outputFile.Write([]byte(yamlDoc))
			require.NoError(t, err)
		}

		// separately handle the ConfigMap case, producing nicer diffs for config files
		if expectedObject.GetKind() == "ConfigMap" {
			var expectedConfigMap corev1.ConfigMap
			var actualConfigMap corev1.ConfigMap
			err = runtime.DefaultUnstructuredConverter.FromUnstructured(expectedObject.UnstructuredContent(), &expectedConfigMap)
			require.NoError(t, err)
			err = runtime.DefaultUnstructuredConverter.FromUnstructured(actualObject.UnstructuredContent(), &actualConfigMap)
			require.NoError(t, err)
			requireConfigMapsEqual(t, expectedConfigMap, actualConfigMap)
		}
		require.Equal(t, expectedObject, *actualObject)
	}

}

// fixupRenderedYaml replaces certain highly variable properties with fixed ones used in the
// expected templates
func fixupRenderedYaml(yaml string, chartVersion string) string {
	checksumRegex := regexp.MustCompile("checksum/config: [a-z0-9]{64}")
	// replacements := map[string]string{
	// 	fmt.Sprintf("app.kubernetes.io/version: \"%s\"", chartVersion): "app.kubernetes.io/version: \"%CURRENT_CHART_VERSION%\"",
	// 	fmt.Sprintf("chart: \"sumologic-%s\"", chartVersion):           "chart: \"sumologic-%CURRENT_CHART_VERSION%\"",
	// 	fmt.Sprintf("chart: sumologic-%s", chartVersion):               "chart: sumologic-%CURRENT_CHART_VERSION%",
	// 	fmt.Sprintf("client: k8s_%s", chartVersion):                    "client: k8s_%CURRENT_CHART_VERSION%",
	// 	fmt.Sprintf("value: \"%s\"", chartVersion):                     "value: \"%CURRENT_CHART_VERSION%\"",
	// }
	replacements := []string{
		"app.kubernetes.io/version: \"%s\"",
		"chart: \"sumologic-%s\"",
		"chart: sumologic-%s",
		"client: k8s_%s",
		"value: \"%s\"",
	}
	output := yaml
	output = strings.ReplaceAll(output, releaseName, "RELEASE-NAME")
	for _, r := range replacements {
		output = strings.ReplaceAll(output, fmt.Sprintf(r, chartVersion), fmt.Sprintf(r, "%CURRENT_CHART_VERSION%"))
	}
	output = checksumRegex.ReplaceAllLiteralString(output, "checksum/config: '%CONFIG_CHECKSUM%'")
	output = strings.TrimSuffix(output, "\n")
	return output
}

func TestFixupRenderedYaml_MultipleOccurrences(t *testing.T) {
	testcases := []struct {
		name         string
		yaml         string
		chartVersion string
		expected     string
	}{
		{
			name: "single occurrence",
			yaml: `
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.kubernetes.io/version: "2.0.0"
  chart: "sumologic-2.0.0"
  client: k8s_2.0.0
  value: "2.0.0"
  another_value: "sumologic-2.0.0"
checksum/config: abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
`,
			chartVersion: "2.0.0",
			expected: `
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.kubernetes.io/version: "%CURRENT_CHART_VERSION%"
  chart: "sumologic-%CURRENT_CHART_VERSION%"
  client: k8s_%CURRENT_CHART_VERSION%
  value: "%CURRENT_CHART_VERSION%"
  another_value: "sumologic-2.0.0"
checksum/config: '%CONFIG_CHECKSUM%'`,
		},
		{
			name: "multiple occurrences",
			yaml: `
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.kubernetes.io/version: "3.0.0"
  chart: "sumologic-3.0.0"
  client: k8s_3.0.0
  value: "3.0.0"
  another_value: "sumologic-3.0.0"
  some_field: "3.0.0"
  yet_another_field: "sumologic-3.0.0"
checksum/config: abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890`,
			chartVersion: "3.0.0",
			expected: `
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.kubernetes.io/version: "%CURRENT_CHART_VERSION%"
  chart: "sumologic-%CURRENT_CHART_VERSION%"
  client: k8s_%CURRENT_CHART_VERSION%
  value: "%CURRENT_CHART_VERSION%"
  another_value: "sumologic-3.0.0"
  some_field: "3.0.0"
  yet_another_field: "sumologic-3.0.0"
checksum/config: '%CONFIG_CHECKSUM%'`,
		},
		{
			name: "no occurrence",
			yaml: `
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.kubernetes.io/version: "4.0.0"
  chart: "sumologic-4.0.0"
  client: k8s_4.0.0
  value: "4.0.0"
checksum/config: abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890`,
			chartVersion: "5.0.0",
			expected: `
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.kubernetes.io/version: "4.0.0"
  chart: "sumologic-4.0.0"
  client: k8s_4.0.0
  value: "4.0.0"
checksum/config: '%CONFIG_CHECKSUM%'`,
		},
	}

	for _, tc := range testcases {
		t.Run(tc.name, func(t *testing.T) {
			fixedYAML := fixupRenderedYaml(tc.yaml, tc.chartVersion)
			assert.Equal(t, tc.expected, fixedYAML, "Unexpected result for test case %s", tc.name)
		})
	}
}

func TestFixupRenderedYaml_NoReplacement(t *testing.T) {
	testcases := []struct {
		name         string
		yaml         string
		chartVersion string
		expected     string
	}{
		{
			name: "no chartVersion present",
			yaml: `
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.kubernetes.io/version: "1.0.0"
  chart: "sumologic-1.0.0"
  client: k8s_1.0.0
  value: "1.0.0"
checksum/config: abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890`,
			chartVersion: "2.0.0",
			expected: `
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.kubernetes.io/version: "1.0.0"
  chart: "sumologic-1.0.0"
  client: k8s_1.0.0
  value: "1.0.0"
checksum/config: '%CONFIG_CHECKSUM%'`,
		},
	}

	for _, tc := range testcases {
		t.Run(tc.name, func(t *testing.T) {
			fixedYAML := fixupRenderedYaml(tc.yaml, tc.chartVersion)
			assert.Equal(t, tc.expected, fixedYAML, "Unexpected result for test case %s", tc.name)
		})
	}
}
