package helm

import (
	"fmt"
	"path"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

func TestBuiltinLabels(t *testing.T) {
	valuesFilePath := path.Join(testDataDirectory, "everything-enabled.yaml")
	chartVersion, err := GetChartVersion()
	require.NoError(t, err)
	renderedYamlString := RenderTemplate(
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

	// split the rendered Yaml into individual documents and unmarshal them into K8s objects
	// we could use the yaml decoder directly, but we'd have to implement our own unmarshaling logic then
	renderedObjects := UnmarshalMultipleFromYaml[unstructured.Unstructured](t, renderedYamlString)

	for _, renderedObject := range renderedObjects {
		if !isSubchartObject(&renderedObject) && renderedObject.GetKind() != "List" {
			object := renderedObject
			objectName := fmt.Sprintf("%s/%s", object.GetKind(), object.GetName())
			t.Run(objectName, func(t *testing.T) {
				checkBuiltinLabels(t, &object, chartVersion)
			})
		}
	}
}

// check the built-in labels added to all K8s objects created by the chart
func checkBuiltinLabels(t *testing.T, object metav1.Object, chartVersion string) {
	labels := object.GetLabels()
	require.Contains(t, labels, "chart")
	require.Contains(t, labels, "heritage")
	require.Contains(t, labels, "release")
	assert.Equal(t, fmt.Sprintf("%s-%s", chartName, chartVersion), labels["chart"])
	assert.Equal(t, releaseName, labels["release"])
	assert.Equal(t, "Helm", labels["heritage"])
}

// isSubchartObject checks if the K8s object was created by a subchart
func isSubchartObject(object metav1.Object) bool {
	var chartLabel string
	var ok bool
	labels := object.GetLabels()
	chartLabel, ok = labels["chart"]
	if !ok {
		chartLabel, ok = labels["helm.sh/chart"]
		if !ok {
			// if we don't have a chart label, we do a final check for subchart name in the object name
			// unfortunately some charts don't set this for some resources so this is the next best thing
			objectName := object.GetName()
			for _, subChartName := range subChartNames {
				if strings.Contains(objectName, subChartName) {
					return true
				}
			}
			return false
		}
	}
	for _, subChartName := range subChartNames {
		if strings.Contains(chartLabel, subChartName) {
			return true
		}
	}

	return false
}
