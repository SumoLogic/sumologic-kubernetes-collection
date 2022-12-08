package helm

import (
	"os"
	"regexp"
	"strings"
	"testing"

	doublestar "github.com/bmatcuk/doublestar/v4"
	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/require"

	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

func TestAllTemplates(t *testing.T) {
	var err error

	chartVersion, err := GetChartVersion()
	require.NoError(t, err)

	// get the template directories
	inputFileNames, err := doublestar.FilepathGlob("**/*.input.yaml")
	require.NoError(t, err)
	require.NotEmpty(t, inputFileNames)
	for _, inputFileName := range inputFileNames { // for each input file name, run the test
		inputFileName := inputFileName
		outputFileName := strings.TrimSuffix(inputFileName, ".input.yaml") + ".output.yaml"
		t.Run(inputFileName, func(t *testing.T) {
			t.Parallel()
			runTemplateTest(t, inputFileName, outputFileName, chartVersion)
		})
	}
}

// runTemplateTest renders the template using the given values file and compares it to the contents
// of the output file
func runTemplateTest(t *testing.T, valuesFileName string, outputFileName string, chartVersion string) {
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
	expectedYamlString := string(expectedYamlBytes)
	// expectedYamlString = fixupExpectedYaml(expectedYamlString)
	require.NoError(t, err)

	var expectedObject unstructured.Unstructured
	var renderedObjects []unstructured.Unstructured
	helm.UnmarshalK8SYaml(t, expectedYamlString, &expectedObject)
	require.NoError(t, err)
	renderedObjects = UnmarshalMultipleFromYaml[unstructured.Unstructured](t, renderedYamlString)
	require.NoError(t, err)

	// find the object we expect
	var actualObject *unstructured.Unstructured = nil
	for _, renderedObject := range renderedObjects {
		if renderedObject.GetName() == expectedObject.GetName() &&
			renderedObject.GetKind() == expectedObject.GetKind() {
			actualObject = &renderedObject
			break
		}
	}
	require.NotNilf(t, actualObject, "Couldn't find object %s/%s in output", expectedObject.GetKind(), expectedObject.GetName())

	require.Equal(t, expectedObject, *actualObject)
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
