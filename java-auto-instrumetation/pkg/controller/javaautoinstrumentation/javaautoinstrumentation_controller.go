package javaautoinstrumentation

import (
	"context"
	"github.com/go-logr/logr"
	"strings"
	"time"

	appv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller"
	"sigs.k8s.io/controller-runtime/pkg/handler"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
	"sigs.k8s.io/controller-runtime/pkg/source"

	javaautoinstrv1alpha1 "github.com/SumoLogic/sumologic-kubernetes-collection/java-auto-instrumentation/pkg/apis/javaautoinstr/v1alpha1"
)

const tracingServiceNameLabel = "auto-instr-service-name"
const needsAutoInstrumentationLabel = "should-auto-instrument"
const autoInstrumentationExporterLabel = "auto-instrumentation-exporter"
const opentelemetryJarVolumeName = "ot-jars-volume"
const opentelemetryJarMountPath = "/ot-jars"
const opentelemetryCollectorHostLabel = "collector-host"
const opentelemetryJarContainerName = "ot-jars-holder"
const opentelemetryJarContainerImage = "quay.io/pioter/ot-jars-holder:v0.2"

var log = logf.Log.WithName("controller_javaautoinstrumentation")

// Add creates a new JavaAutoInstrumentation Controller and adds it to the Manager. The Manager will set fields on the Controller
// and Start it when the Manager is Started.
func Add(mgr manager.Manager) error {
	return add(mgr, newReconciler(mgr))
}

// newReconciler returns a new reconcile.Reconciler
func newReconciler(mgr manager.Manager) reconcile.Reconciler {
	return &ReconcileJavaAutoInstrumentation{client: mgr.GetClient(), scheme: mgr.GetScheme()}
}

// add adds a new Controller to mgr with r as the reconcile.Reconciler
func add(mgr manager.Manager, r reconcile.Reconciler) error {
	// Create a new controller
	c, err := controller.New("javaautoinstrumentation-controller", mgr, controller.Options{Reconciler: r})
	if err != nil {
		return err
	}

	// Watch for changes to primary resource JavaAutoInstrumentation
	err = c.Watch(&source.Kind{Type: &javaautoinstrv1alpha1.JavaAutoInstrumentation{}}, &handler.EnqueueRequestForObject{})
	if err != nil {
		return err
	}

	// Watch for changes to secondary resource Pods and requeue the owner JavaAutoInstrumentation
	err = c.Watch(&source.Kind{Type: &corev1.Pod{}}, &handler.EnqueueRequestForOwner{
		IsController: true,
		OwnerType:    &javaautoinstrv1alpha1.JavaAutoInstrumentation{},
	})
	if err != nil {
		return err
	}

	log.Info("Watching all deployments")
	err = c.Watch(&source.Kind{Type: &appv1.Deployment{}}, &handler.EnqueueRequestForObject{})
	if err != nil {
		log.Error(err, "Failed to watch all deployments")
		return err
	}
	return nil
}

// blank assignment to verify that ReconcileJavaAutoInstrumentation implements reconcile.Reconciler
var _ reconcile.Reconciler = &ReconcileJavaAutoInstrumentation{}

// ReconcileJavaAutoInstrumentation reconciles a JavaAutoInstrumentation object
type ReconcileJavaAutoInstrumentation struct {
	// This client, initialized using mgr.Client() above, is a split client
	// that reads objects from the cache and writes to the apiserver
	client client.Client
	scheme *runtime.Scheme
}

// Reconcile reads that state of the cluster for a JavaAutoInstrumentation object and makes changes based on the state read
// and what is in the JavaAutoInstrumentation.Spec
// Note:
// The Controller will requeue the Request to be processed again if the returned error is non-nil or
// Result.Requeue is true, otherwise upon completion it will remove the work from the queue.
func (r *ReconcileJavaAutoInstrumentation) Reconcile(request reconcile.Request) (reconcile.Result, error) {
	now := time.Now().Format(time.RFC3339)
	reqLogger := log.WithValues("Request.Namespace", request.Namespace, "Request.Name", request.Name,
		"Timestamp", now)
	reqLogger.Info("Reconciling JavaAutoInstrumentation")

	existingDeployments := &appv1.DeploymentList{}
	err := r.client.List(context.TODO(), existingDeployments, &client.ListOptions{Namespace: request.Namespace})
	if err != nil {
		reqLogger.Error(err, "failed to list existing deployments")
		return reconcile.Result{}, err
	}

	for _, deployment := range existingDeployments.Items {
		reqLogger.Info("Processing", "deployment", deployment.Name)
		if needsAutoInstrumentation(&deployment) {
			if !hasJavaOptionsEnvVarWithAutoInstrumentation(deployment.Spec.Template.Spec.Containers) {
				reqLogger.Info("Containers do not have _JAVA_OPTIONS env var with auto instrumentation",
					"Deployment", deployment.Name)
				exporter := getAutoInstrumentationExporterOrDefault(reqLogger, &deployment)
				collectorHost := getCollectorHostOrDefault(&deployment, exporter)
				tracingServiceName := getAutoInstrumentationServiceName(reqLogger, &deployment)
				deployment.Spec.Template.Spec = mergePodSpec(&deployment.Spec.Template.Spec, tracingServiceName,
					exporter, collectorHost)
				err = r.client.Update(context.TODO(), &deployment)
				if err != nil {
					reqLogger.Error(err, "Failed to update deployment", "Deployment", deployment.Name)
					return reconcile.Result{}, err
				} else {
					reqLogger.Info("Successfully updated deployment", "Deployment", deployment.Name)
				}
			} else {
				reqLogger.Info("Containers have _JAVA_OPTIONS with auto instrumentation, will leave them alone")
			}
		} else {
			reqLogger.Info("This deployment doesn't need auto instrumentation")
		}
	}
	return reconcile.Result{}, nil
}

func getCollectorHostOrDefault(deployment *appv1.Deployment, exporter string) string {
	providedHost, ok := deployment.Labels[opentelemetryCollectorHostLabel]
	if ok {
		return providedHost
	} else {
		return exporter
	}
}

func hasJavaOptionsEnvVarWithAutoInstrumentation(containers []corev1.Container) bool {
	options, exists := getJavaOptions(containers)
	return exists && strings.Contains(options, "opentelemetry-auto")
}

func getJavaOptions(containers []corev1.Container) (string, bool) {
	for _, container := range containers {
		for _, e := range container.Env {
			if e.Name == "_JAVA_OPTIONS" {
				return e.Value, true
			}
		}
	}
	return "", false
}

func needsAutoInstrumentation(deployment *appv1.Deployment) bool {
	shouldAutoInstrument, ok := deployment.Labels[needsAutoInstrumentationLabel]
	if ok {
		return shouldAutoInstrument == "true"
	}
	return false
}

func getAutoInstrumentationExporterOrDefault(reqLogger logr.Logger, deployment *appv1.Deployment) string {
	exporter, ok := deployment.Labels[autoInstrumentationExporterLabel]
	if ok {
		if exporter == "jaeger" || exporter == "otlp" {
			return exporter
		} else {
			reqLogger.Info("Unknown exporter "+exporter+", will default to jaeger", "Deployment",
				deployment.Name)
			return "jaeger"
		}
	} else {
		reqLogger.Info("No exporter set, will default to jaeger", "Deployment",
			deployment.Name)
		return "jaeger"
	}
}

func getAutoInstrumentationServiceName(reqLogger logr.Logger, deployment *appv1.Deployment) string {
	name, ok := deployment.Labels[tracingServiceNameLabel]
	if ok {
		reqLogger.Info("Using label for tracing service name")
		return name
	} else {
		podSpec := deployment.Spec.Template.Spec
		numberOfContainers := len(podSpec.Containers)
		reqLogger.Info("Using pod container for tracing service name", "Number of containers",
			numberOfContainers)
		return podSpec.Hostname + "-" + podSpec.Containers[0].Name
	}
}

func getJaegerConfiguration(serviceName string, existingJavaOptions string, collectorHost string) []corev1.EnvVar {
	return []corev1.EnvVar{
		{
			Name: "_JAVA_OPTIONS",
			Value: existingJavaOptions + " -javaagent:" + opentelemetryJarMountPath + "/opentelemetry-auto-0.3.0.jar " +
				"-Dota.exporter.jar=" + opentelemetryJarMountPath + "/opentelemetry-auto-exporters-jaeger-0.3.0.jar " +
				"-Dota.exporter.jaeger.endpoint=" + collectorHost + ":14250 " +
				"-Dota.exporter.jaeger.service.name=" + serviceName,
		},
	}
}

func getOtlpConfiguration(serviceName string, existingJavaOptions string, collectorHost string) []corev1.EnvVar {
	return []corev1.EnvVar{
		{
			Name: "_JAVA_OPTIONS",
			Value: existingJavaOptions + " -javaagent:" + opentelemetryJarMountPath + "/opentelemetry-auto-0.3.0.jar " +
				"-Dota.exporter.jar=" + opentelemetryJarMountPath + "/opentelemetry-auto-exporters-otlp-0.3.0.jar " +
				"-Dota.exporter.otlp.endpoint=" + collectorHost + ":55680",
		},
		{
			Name:  "OTEL_RESOURCE_ATTRIBUTES",
			Value: "service.name=" + serviceName,
		},
	}
}

func getConfiguration(exporter string, serviceName string, existingJavaOptions string,
	collectorHost string) []corev1.EnvVar {

	if exporter == "otlp" {
		return getOtlpConfiguration(serviceName, existingJavaOptions, collectorHost)
	} else {
		return getJaegerConfiguration(serviceName, existingJavaOptions, collectorHost)
	}
}

func copyExistingEnvVarsWithoutJavaOptions(env []corev1.EnvVar) []corev1.EnvVar {
	var envVars []corev1.EnvVar
	for _, e := range env {
		if e.Name != "_JAVA_OPTIONS" {
			envVars = append(envVars, e)
		}
	}
	return envVars
}

func getOtJarsVolumeMount() corev1.VolumeMount {
	return corev1.VolumeMount{
		Name:      opentelemetryJarVolumeName,
		MountPath: opentelemetryJarMountPath,
	}
}

func getOtJarsVolume() corev1.Volume {
	return corev1.Volume{
		Name: opentelemetryJarVolumeName,
		VolumeSource: corev1.VolumeSource{
			EmptyDir: &corev1.EmptyDirVolumeSource{},
		},
	}
}

func mergePodSpec(originalPodSpec *corev1.PodSpec, serviceName string, exporter string,
	collectorHost string) corev1.PodSpec {

	originalContainer := originalPodSpec.Containers[0] // TODO
	existingJavaOptions, exists := getJavaOptions(originalPodSpec.Containers)
	if !exists {
		existingJavaOptions = ""
	}
	var envVars = copyExistingEnvVarsWithoutJavaOptions(originalContainer.Env)
	envVars = append(envVars, getConfiguration(exporter, serviceName, existingJavaOptions, collectorHost)...)

	otJarsVolumeMount := getOtJarsVolumeMount()
	var volumeMounts []corev1.VolumeMount
	volumeMounts = append(volumeMounts, originalContainer.VolumeMounts...)
	volumeMounts = append(volumeMounts, otJarsVolumeMount)

	var volumes []corev1.Volume
	volumes = append(volumes, originalPodSpec.Volumes...)
	volumes = append(volumes, getOtJarsVolume())

	initContainers := append(originalPodSpec.InitContainers, getOtJarsInitContainer(otJarsVolumeMount))

	return corev1.PodSpec{
		Volumes:        volumes,
		InitContainers: initContainers,
		Containers: []corev1.Container{
			{
				Name:                     originalContainer.Name,
				Image:                    originalContainer.Image,
				Resources:                originalContainer.Resources,
				SecurityContext:          originalContainer.SecurityContext,
				Env:                      envVars,
				VolumeMounts:             volumeMounts,
				Command:                  originalContainer.Command,
				Args:                     originalContainer.Args,
				WorkingDir:               originalContainer.WorkingDir,
				Ports:                    originalContainer.Ports,
				EnvFrom:                  originalContainer.EnvFrom,
				VolumeDevices:            originalContainer.VolumeDevices,
				LivenessProbe:            originalContainer.LivenessProbe,
				ReadinessProbe:           originalContainer.ReadinessProbe,
				StartupProbe:             originalContainer.StartupProbe,
				Lifecycle:                originalContainer.Lifecycle,
				TerminationMessagePath:   originalContainer.TerminationMessagePath,
				TerminationMessagePolicy: originalContainer.TerminationMessagePolicy,
				ImagePullPolicy:          originalContainer.ImagePullPolicy,
				Stdin:                    originalContainer.Stdin,
				StdinOnce:                originalContainer.StdinOnce,
				TTY:                      originalContainer.TTY,
			},
		},
		EphemeralContainers:           originalPodSpec.EphemeralContainers,
		RestartPolicy:                 originalPodSpec.RestartPolicy,
		TerminationGracePeriodSeconds: originalPodSpec.TerminationGracePeriodSeconds,
		ActiveDeadlineSeconds:         originalPodSpec.ActiveDeadlineSeconds,
		DNSPolicy:                     originalPodSpec.DNSPolicy,
		NodeSelector:                  originalPodSpec.NodeSelector,
		ServiceAccountName:            originalPodSpec.ServiceAccountName,
		DeprecatedServiceAccount:      originalPodSpec.DeprecatedServiceAccount,
		AutomountServiceAccountToken:  originalPodSpec.AutomountServiceAccountToken,
		NodeName:                      originalPodSpec.NodeName,
		HostNetwork:                   originalPodSpec.HostNetwork,
		HostPID:                       originalPodSpec.HostPID,
		HostIPC:                       originalPodSpec.HostIPC,
		ShareProcessNamespace:         originalPodSpec.ShareProcessNamespace,
		SecurityContext:               originalPodSpec.SecurityContext,
		ImagePullSecrets:              originalPodSpec.ImagePullSecrets,
		Hostname:                      originalPodSpec.Hostname,
		Subdomain:                     originalPodSpec.Subdomain,
		Affinity:                      originalPodSpec.Affinity,
		SchedulerName:                 originalPodSpec.SchedulerName,
		Tolerations:                   originalPodSpec.Tolerations,
		HostAliases:                   originalPodSpec.HostAliases,
		PriorityClassName:             originalPodSpec.PriorityClassName,
		Priority:                      originalPodSpec.Priority,
		DNSConfig:                     originalPodSpec.DNSConfig,
		ReadinessGates:                originalPodSpec.ReadinessGates,
		RuntimeClassName:              originalPodSpec.RuntimeClassName,
		EnableServiceLinks:            originalPodSpec.EnableServiceLinks,
		PreemptionPolicy:              originalPodSpec.PreemptionPolicy,
		Overhead:                      originalPodSpec.Overhead,
		TopologySpreadConstraints:     originalPodSpec.TopologySpreadConstraints,
	}
}

func getOtJarsInitContainer(volumeMount corev1.VolumeMount) corev1.Container {
	return corev1.Container{
		Name:         opentelemetryJarContainerName,
		Image:        opentelemetryJarContainerImage,
		VolumeMounts: []corev1.VolumeMount{volumeMount},
	}
}
