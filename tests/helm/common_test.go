package helm

import (
	"fmt"
	"path"
	"reflect"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/logger"

	otelv1alpha1 "github.com/open-telemetry/opentelemetry-operator/apis/v1alpha1"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	appsv1 "k8s.io/api/apps/v1"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
)

func TestK8sResourceValidation(t *testing.T) {
	valuesFilePath := path.Join(testDataDirectory, "everything-enabled.yaml")
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

	_, err := UnmarshalMultipleK8sObjectsFromYaml(renderedYamlString)
	require.NoError(t, err)
}

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

func TestNodeSelector(t *testing.T) {
	t.Parallel()
	valuesFilePath := path.Join(testDataDirectory, "node-selector.yaml")
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
		nodeSelector, err := GetNodeSelector(renderedObject)
		require.NoError(t, err)
		// If we ever set some default nodeSelector anywhere, this might stop working,
		// as this assumes that the only nodeSelector will be the one in node-selector.yaml
		if nodeSelector != nil {
			nsv, ok := nodeSelector[nodeSelectorKey]
			assert.True(
				t,
				ok,
				"%s should have %s nodeSelector",
				renderedObject.GetName(),
				nodeSelectorKey,
			)

			assert.True(
				t,
				nsv == nodeSelectorValue,
				"%s should have nodeSelector %s set to %s, found %s instead",
				renderedObject.GetName(),
				nodeSelectorKey,
				nodeSelectorValue,
				nsv,
			)
		}
	}
}

func TestTolerations(t *testing.T) {
	t.Parallel()
	valuesFilePath := path.Join(testDataDirectory, "node-selector.yaml")
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
		tolerations, err := GetTolerations(renderedObject)
		require.NoError(t, err)
		// If we ever set some default nodeSelector anywhere, this might stop working,
		// as this assumes that the only nodeSelector will be the one in node-selector.yaml
		if tolerations != nil {
			assert.True(
				t,
				len(tolerations) == 1,
				"%s has tolerations of length %s, should be 1",
				renderedObject.GetName(),
				len(tolerations),
			)
			tol := tolerations[0]

			assert.True(
				t,
				tol == toleration,
				"%s should have toleration set to %s, found %s instead",
				renderedObject.GetName(),
				toleration,
				tol,
			)
		}
	}
}

func TestAffinities(t *testing.T) {
	t.Parallel()
	valuesFilePath := path.Join(testDataDirectory, "node-selector.yaml")
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
		aff, err := GetAffinity(renderedObject)
		require.NoError(t, err)
		// Objects that are not subject to global settings:
		excluded := map[string]bool{
			"col-test-sumologic-otelcol-events": true,
		}
		// Check only node affinity, to avoid checking anti affinities
		if _, ok := excluded[renderedObject.GetName()]; !ok && aff != nil {
			assert.NotNil(t, aff.NodeAffinity, "%s", renderedObject.GetName())
			assert.True(
				t,
				reflect.DeepEqual(*aff.NodeAffinity, *affinity.NodeAffinity),
				"%s should have node affinity set to %s, found %s instead",
				renderedObject.GetName(),
				affinity,
				aff,
			)
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
	case "Job":
		jobs := &batchv1.Job{}
		err := runtime.DefaultUnstructuredConverter.FromUnstructured(object.Object, &jobs)
		if err != nil {
			return nil, err
		}
		return &jobs.Spec.Template.Spec, nil
	case "CronJob":
		jobs := &batchv1.CronJob{}
		err := runtime.DefaultUnstructuredConverter.FromUnstructured(object.Object, &jobs)
		if err != nil {
			return nil, err
		}
		return &jobs.Spec.JobTemplate.Spec.Template.Spec, nil
	default:
		return nil, nil
	}
}

func GetNodeSelector(object unstructured.Unstructured) (map[string]string, error) {
	podSpec, err := GetPodSpec(object)
	if err != nil {
		return nil, err
	} else if podSpec != nil {
		return podSpec.NodeSelector, nil
	}

	if object.GetKind() == "OpenTelemetryCollector" {
		otelcol := &otelv1alpha1.OpenTelemetryCollector{}
		err := runtime.DefaultUnstructuredConverter.FromUnstructured(object.Object, &otelcol)
		if err != nil {
			return nil, err
		}
		return otelcol.Spec.NodeSelector, nil
	}

	return nil, nil
}
func GetAffinity(object unstructured.Unstructured) (*corev1.Affinity, error) {
	podSpec, err := GetPodSpec(object)
	if err != nil {
		return nil, err
	} else if podSpec != nil {
		return podSpec.Affinity, nil
	}

	return nil, nil
}

func GetTolerations(object unstructured.Unstructured) ([]corev1.Toleration, error) {
	podSpec, err := GetPodSpec(object)
	if err != nil {
		return nil, err
	} else if podSpec != nil {
		return podSpec.Tolerations, nil
	}

	if object.GetKind() == "OpenTelemetryCollector" {
		otelcol := &otelv1alpha1.OpenTelemetryCollector{}
		err := runtime.DefaultUnstructuredConverter.FromUnstructured(object.Object, &otelcol)
		if err != nil {
			return nil, err
		}
		return otelcol.Spec.Tolerations, nil
	}

	return nil, nil
}

func TestNamespaceOverride(t *testing.T) {
	valuesFilePath := path.Join(testDataDirectory, "everything-enabled.yaml")
	namespaceOverride := "override"
	renderedYamlString := RenderTemplate(
		t,
		&helm.Options{
			ValuesFiles: []string{valuesFilePath},
			SetStrValues: map[string]string{
				"sumologic.accessId":  "accessId",
				"sumologic.accessKey": "accessKey",
				"namaespaceOverride":  namespaceOverride,
			},
			Logger: logger.Discard, // the log output is noisy and doesn't help much
		},
		chartDirectory,
		releaseName,
		[]string{},
		true,
		"--namespace",
		"override",
	)

	// split the rendered Yaml into individual documents and unmarshal them into K8s objects
	// we could use the yaml decoder directly, but we'd have to implement our own unmarshaling logic then
	renderedObjects := UnmarshalMultipleFromYaml[unstructured.Unstructured](t, renderedYamlString)

	for _, renderedObject := range renderedObjects {
		if !isSubchartObject(&renderedObject) && renderedObject.GetKind() != "List" {
			object := renderedObject
			objectName := fmt.Sprintf("%s/%s", object.GetKind(), object.GetName())
			t.Run(objectName, func(t *testing.T) {
				namespace := object.GetNamespace()
				if namespace != "" {
					require.Equal(t, namespaceOverride, object.GetNamespace())
				}
			})
		}
	}
}

func TestServiceAccountPullSecrets(t *testing.T) {
	expectedPullSecrets := []string{"pullSecret"}
	valuesFilePath := path.Join(testDataDirectory, "everything-enabled.yaml")
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

	objects, err := UnmarshalMultipleK8sObjectsFromYaml(renderedYamlString)
	require.NoError(t, err)

	for _, object := range objects {
		kind := object.GetObjectKind().GroupVersionKind().Kind
		if kind != "ServiceAccount" {
			continue
		}
		serviceAccount := object.(*corev1.ServiceAccount)
		if isSubchartObject(serviceAccount) {
			continue
		}

		objectName := fmt.Sprintf("%s/%s", "ServiceAccount", serviceAccount.GetName())
		t.Run(objectName, func(t *testing.T) {
			actualPullSecrets := []string{}
			for _, pullSecretRef := range serviceAccount.ImagePullSecrets {
				actualPullSecrets = append(actualPullSecrets, pullSecretRef.Name)
			}
			assert.Equal(t, expectedPullSecrets, actualPullSecrets)
		})
	}
}
