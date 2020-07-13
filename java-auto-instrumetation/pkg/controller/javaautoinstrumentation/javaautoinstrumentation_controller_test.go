package javaautoinstrumentation

import (
	"github.com/stretchr/testify/assert"
	appv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"strings"

	"testing"
)

var testLogger = log.WithValues("Environment", "in test")

func TestShouldFindThatDeploymentNeedsAutoInstrumentation(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{
		"should-auto-instrument": "true",
	})

	// when
	needsAutoInstrumentation := needsAutoInstrumentation(deployment)

	// then
	assert.True(t, needsAutoInstrumentation)
}

func TestShouldFindThatDeploymentHasAutoInstrumentationDisabled(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{
		"should-auto-instrument": "false",
	})

	// when
	needsAutoInstrumentation := needsAutoInstrumentation(deployment)

	// then
	assert.False(t, needsAutoInstrumentation)
}

func TestShouldFindThatDeploymentDoesntNeedAutoInstrumentation(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{})

	// when
	needsAutoInstrumentation := needsAutoInstrumentation(deployment)

	// then
	assert.False(t, needsAutoInstrumentation)
}

func TestShouldFindJavaOptionsWithOpenTelemetryForOneContainer(t *testing.T) {
	// given
	container := buildContainer("_JAVA_OPTIONS", "-javaagent:/ot-jars/opentelemetry-auto-0.3.0.jar")

	// when
	hasAutoInstrJavaOpt := hasJavaOptionsEnvVarWithAutoInstrumentation([]corev1.Container{*container})

	// then
	assert.True(t, hasAutoInstrJavaOpt)
}

func TestShouldNotFindJavaOptionsWithOpenTelemetryForOneContainer(t *testing.T) {
	// given
	container := buildContainer("_JAVA_OPTIONS", "an option")

	// when
	hasAutoInstrJavaOpt := hasJavaOptionsEnvVarWithAutoInstrumentation([]corev1.Container{*container})

	// then
	assert.False(t, hasAutoInstrJavaOpt)
}

func TestShouldNotFindJavaOptionsForOneContainer(t *testing.T) {
	// given
	container := buildContainer("some env variable", "an option")

	// when
	hasAutoInstrJavaOpt := hasJavaOptionsEnvVarWithAutoInstrumentation([]corev1.Container{*container})

	// then
	assert.False(t, hasAutoInstrJavaOpt)
}

func TestShouldUseDefaultExporterIfNoExplicitOneFound(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{})

	// when
	exporter := getAutoInstrumentationExporterOrDefault(testLogger, deployment)

	// then
	assert.Equal(t, "jaeger", exporter)
}

func TestShouldUseJaegerExporterExplicitly(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{
		"auto-instrumentation-exporter": "jaeger",
	})

	// when
	exporter := getAutoInstrumentationExporterOrDefault(testLogger, deployment)

	// then
	assert.Equal(t, "jaeger", exporter)
}

func TestShouldUseOtlpExporterExplicitly(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{
		"auto-instrumentation-exporter": "otlp",
	})

	// when
	exporter := getAutoInstrumentationExporterOrDefault(testLogger, deployment)

	// then
	assert.Equal(t, "otlp", exporter)
}

func TestShouldFallbackToJaegerExporterWhenExporterIsUnknown(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{
		"auto-instrumentation-exporter": "unknown exporter",
	})

	// when
	exporter := getAutoInstrumentationExporterOrDefault(testLogger, deployment)

	// then
	assert.Equal(t, "jaeger", exporter)
}

func TestShouldUseServiceNameFromLabel(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{
		"auto-instr-service-name": "my cool service",
	})

	// when
	serviceName := getAutoInstrumentationServiceName(testLogger, deployment)

	// then
	assert.Equal(t, "my cool service", serviceName)
}

func TestShouldUsePodHostnameAndContainerNameAsServiceName(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{})

	// when
	serviceName := getAutoInstrumentationServiceName(testLogger, deployment)

	// then
	// take a look at how the deployment is built
	assert.Equal(t, "podHost-container1", serviceName)
}

func TestShouldBuildJaegerConfiguration(t *testing.T) {
	// given
	serviceName := "super-app"
	existingOpts := "some-opts"
	collectorHost := "jaeger-host"

	// when
	config := getJaegerConfiguration(serviceName, existingOpts, collectorHost)

	// then
	assert.Equal(t, 1, len(config))
	assert.Equal(t, "_JAVA_OPTIONS", config[0].Name)
	assert.True(t, strings.HasPrefix(config[0].Value, existingOpts))
	assert.True(t, strings.HasSuffix(config[0].Value, serviceName))
	assert.True(t, strings.Contains(config[0].Value, collectorHost))
}

func TestShouldBuildOtlpConfiguration(t *testing.T) {
	// given
	serviceName := "super-app"
	existingOpts := "some-opts"
	collectorHost := "otlp-host"

	// when
	config := getOtlpConfiguration(serviceName, existingOpts, collectorHost)

	// then
	assert.Equal(t, 2, len(config))
	assert.Equal(t, "_JAVA_OPTIONS", config[0].Name)
	assert.True(t, strings.HasPrefix(config[0].Value, existingOpts))
	assert.Equal(t, "OTEL_RESOURCE_ATTRIBUTES", config[1].Name)
	assert.True(t, strings.HasSuffix(config[1].Value, serviceName))
	assert.True(t, strings.Contains(config[0].Value, collectorHost))
}

func TestShouldChooseJaegerConfiguration(t *testing.T) {
	// given
	serviceName := "super-app"
	existingOpts := "some-opts"
	exporter := "jaeger"

	// when
	config := getConfiguration(exporter, serviceName, existingOpts, exporter)

	// then
	assert.Equal(t, 1, len(config))
	assert.True(t, strings.Contains(config[0].Value, exporter))
}

func TestShouldChooseOtlpConfiguration(t *testing.T) {
	// given
	serviceName := "super-app"
	existingOpts := "some-opts"
	exporter := "otlp"

	// when
	config := getConfiguration(exporter, serviceName, existingOpts, exporter)

	// then
	assert.Equal(t, 2, len(config))
	assert.True(t, strings.Contains(config[0].Value, exporter))
}

func TestShouldFallbackToJaegerConfigurationForUnknownExporter(t *testing.T) {
	// given
	serviceName := "super-app"
	existingOpts := "some-opts"
	exporter := "unknown"

	// when
	config := getConfiguration(exporter, serviceName, existingOpts, "jaeger")

	// then
	assert.Equal(t, 1, len(config))
	assert.True(t, strings.Contains(config[0].Value, "jaeger"))
}

func TestShouldCopyWithoutJavaOptions(t *testing.T) {
	// given
	envVars := []corev1.EnvVar{
		{Name: "E1", Value: "v1"},
		{Name: "_JAVA_OPTIONS", Value: "gc"},
		{Name: "E3", Value: "v3"},
	}

	// when
	copiedEnvVars := copyExistingEnvVarsWithoutJavaOptions(envVars)

	// then
	assert.Equal(t, 2, len(copiedEnvVars))
	assert.Equal(t, "E1", copiedEnvVars[0].Name)
	assert.Equal(t, "E3", copiedEnvVars[1].Name)
}

func TestShouldBuildOtJarsVolumeMount(t *testing.T) {
	// given
	volumeMount := getOtJarsVolumeMount()

	// expect
	assert.False(t, volumeMount.ReadOnly)
	assert.Equal(t, "ot-jars-volume", volumeMount.Name)
	assert.Equal(t, "/ot-jars", volumeMount.MountPath)
}

func TestShouldBuildOtJarsVolume(t *testing.T) {
	// given
	volume := getOtJarsVolume()

	// expect
	assert.Equal(t, "ot-jars-volume", volume.Name)
}

func TestShouldEnableAutoInstrumentation(t *testing.T) {
	// given
	originalPodSpec := buildPodSpecForIntegration()
	serviceName := "my-cool-service"
	exporter := "jaeger"

	// when
	newPod := mergePodSpec(&originalPodSpec, serviceName, exporter, exporter)

	// then
	assert.Equal(t, 2, len(newPod.Volumes))
	assert.Equal(t, 2, len(newPod.Containers[0].Env))
}

func TestShouldFindCollectorHostFromDeploymentLabel(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{
		"collector-host": "ec2 machine",
	})

	// when
	host := getCollectorHostOrDefault(deployment, "")

	// then
	assert.Equal(t, "ec2 machine", host)
}

func TestShouldUseExporterNameAsHostWhenNoLabelProvided(t *testing.T) {
	// given
	deployment := buildDeployment(map[string]string{})
	exporter := "my exporter"

	// when
	host := getCollectorHostOrDefault(deployment, exporter)

	// then
	assert.Equal(t, exporter, host)
}

func TestShouldAddInitContainer(t *testing.T) {
	// given
	originalPodSpec := buildPodSpecForIntegration()
	assert.Equal(t, 0, len(originalPodSpec.InitContainers))

	// when
	newPodSpec := mergePodSpec(&originalPodSpec, "service", "exporter", "collector")

	// then
	assert.Equal(t, 1, len(newPodSpec.InitContainers))
}

func buildContainer(name string, value string) *corev1.Container {
	return &corev1.Container{
		Env: []corev1.EnvVar{
			{
				Name:  name,
				Value: value,
			},
		},
	}
}

func buildDeployment(labels map[string]string) *appv1.Deployment {
	return &appv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:              "auth-service-abc12-xyz3",
			Namespace:         "ns1",
			UID:               "33333",
			CreationTimestamp: metav1.Now(),
			ClusterName:       "cluster1",
			Labels:            labels,
			Annotations: map[string]string{
				"annotation1": "av1",
			},
			OwnerReferences: []metav1.OwnerReference{
				{
					Kind: "ReplicaSet",
					Name: "foo-bar-rs",
					UID:  "1a1658f9-7818-11e9-90f1-02324f7e0d1e",
				},
			},
		},
		Spec: appv1.DeploymentSpec{
			Template: corev1.PodTemplateSpec{
				Spec: corev1.PodSpec{
					Hostname: "podHost",
					Containers: []corev1.Container{
						{
							Name: "container1",
						},
						{
							Name: "container2",
						},
					},
				},
			},
		},
	}
}

func buildPodSpecForIntegration() corev1.PodSpec {
	return corev1.PodSpec{
		Containers: []corev1.Container{
			{
				Name:  "my container",
				Image: "cool docker image",
				Env: []corev1.EnvVar{
					{
						Name:  "my env value",
						Value: "something",
					},
				},
			},
		},
		Volumes: []corev1.Volume{
			{
				Name: "original volume",
				VolumeSource: corev1.VolumeSource{
					HostPath: &corev1.HostPathVolumeSource{
						Path: "/my-bin",
					},
				},
			},
		},
	}
}
