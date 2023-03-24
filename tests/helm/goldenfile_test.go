package helm

import (
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
	inputFileNames, err := doublestar.FilepathGlob("**/*.input.yaml")
	require.NoError(t, err)
	require.NotEmpty(t, inputFileNames)
	for _, inputFileName := range inputFileNames { // for each input file name, run the test
		inputFileName := inputFileName
		outputFileName := strings.TrimSuffix(inputFileName, ".input.yaml") + ".output.yaml"
		t.Run(inputFileName, func(t *testing.T) {
			t.Parallel()
			runGoldenFileTest(t, inputFileName, outputFileName, chartVersion)
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
			preYamlDocuments := strings.Split(renderedYamlString, "---")
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
	output := yaml
	output = strings.ReplaceAll(output, releaseName, "RELEASE-NAME")
	output = strings.ReplaceAll(output, chartVersion, "%CURRENT_CHART_VERSION%")
	output = checksumRegex.ReplaceAllLiteralString(output, "checksum/config: '%CONFIG_CHECKSUM%'")
	output = strings.TrimSuffix(output, "\n")
	return output
}
