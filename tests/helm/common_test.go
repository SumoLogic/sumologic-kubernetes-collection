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
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
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

func TestOtelImageFIPSSuffix(t *testing.T) {
	t.Parallel()
	valuesFilePath := path.Join(testDataDirectory, "fipsmode.yaml")
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
		podSpec, err := GetPodSpec(renderedObject)
		require.NoError(t, err)
		if podSpec != nil {
			for _, container := range podSpec.Containers {
				if container.Name == otelContainerName {
					assert.True(
						t,
						strings.HasSuffix(container.Image, otelImageFIPSSuffix),
						"%s should have %s suffix",
						container.Name,
						otelImageFIPSSuffix,
					)
				}
			}
		}
	}
}
func TestNameAndLabelLength(t *testing.T) {
	// object kinds whose names are limited to 63 characters instead of K8s default of 253
	// not all of these are strictly required, but it's a good practice to limit them regardless
	limitedNameKinds := []string{
		"Pod",
		"Service",
		"Deployment",
		"DaemonSet",
		"StatefulSet",
	}
	valuesFilePath := path.Join(testDataDirectory, "everything-enabled.yaml")
	releaseName := strings.Repeat("a", maxHelmReleaseNameLength)
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
		name := renderedObject.GetName()
		kind := renderedObject.GetKind()
		maxNameLength := k8sMaxNameLength
		for _, limitedNameKind := range limitedNameKinds {
			if kind == limitedNameKind {
				maxNameLength = k8sMaxLabelLength
			}
		}
		assert.LessOrEqualf(t, len(name), maxNameLength, "object kind `%s` name `%s` must be no more than %d characters", renderedObject.GetKind(), name, maxNameLength)
		labels := renderedObject.GetLabels()
		for key, value := range labels {
			assert.LessOrEqualf(t, len(value), k8sMaxLabelLength, "value of label %s=%s must be no more than %d characters", key, value, k8sMaxLabelLength)
		}
	}
}

func TestReleaseNameTooLong(t *testing.T) {
	valuesFilePath := path.Join(testDataDirectory, "everything-enabled.yaml")
	releaseName := strings.Repeat("a", maxHelmReleaseNameLength+1)
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
	require.NoError(t, err)
	// we can't check whether NOTES are rendered correctly due to https://github.com/helm/helm/issues/6901
	// TODO: Add an error check here after we start enforcing the limit: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/3057
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

// Get a PodSpec from the unstructured object, if possible
// This only works on Deployments, StatefulSets and DaemonSets
func GetPodSpec(object unstructured.Unstructured) (*corev1.PodSpec, error) {
	switch object.GetKind() {
	case "Deployment":
		deployment := &appsv1.Deployment{}
		err := runtime.DefaultUnstructuredConverter.FromUnstructured(object.Object, &deployment)
		if err != nil {
			return nil, err
		}
		return &deployment.Spec.Template.Spec, nil
	case "StatefulSet":
		statefulset := &appsv1.StatefulSet{}
		err := runtime.DefaultUnstructuredConverter.FromUnstructured(object.Object, &statefulset)
		if err != nil {
			return nil, err
		}
		return &statefulset.Spec.Template.Spec, nil
	case "DaemonSet":
		daemonset := &appsv1.DaemonSet{}
		err := runtime.DefaultUnstructuredConverter.FromUnstructured(object.Object, &daemonset)
		if err != nil {
			return nil, err
		}
		return &daemonset.Spec.Template.Spec, nil
	default:
		return nil, nil
	}
}
