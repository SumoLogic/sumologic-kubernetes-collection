package tracesgenerator

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	generatorBinaryName = "customer-trace-tester"
	deploymentSleepTime = time.Hour * 24 // how much time we spend sleeping after generating logs in a Deployment
)

type TracesGeneratorOptions struct {
	// For all of these options, 0 and "" respectively are treated as "not set"

	// Total number of traces generated per exporter
	TracesPerExporter uint
	// Number of spans per every trace
	SpansPerTrace uint

	// Exporter options
	otlpHttpEnabled  bool
	otlpGrpcEnabled  bool
	zipkinEnabled    bool
	jaegerThriftHttp bool
}

func NewDefaultGeneratorOptions() *TracesGeneratorOptions {
	return &TracesGeneratorOptions{
		TracesPerExporter: 40,
		SpansPerTrace:     5,
		otlpHttpEnabled:   true,
		otlpGrpcEnabled:   true,
		zipkinEnabled:     true,
		jaegerThriftHttp:  true,
	}
}

func GetTracesGeneratorDeployment(
	ctx context.Context,
	namespace string,
	name string,
	image string,
	options TracesGeneratorOptions,
) appsv1.Deployment {
	var replicas int32 = 1
	appLabels := map[string]string{
		"app": name,
	}
	metadata := metav1.ObjectMeta{
		Name:      name,
		Namespace: namespace,
		Labels:    appLabels,
	}

	release := ctxopts.HelmRelease(ctx)
	otelcolInstrumentationNamespace := ctxopts.Namespace(ctx)
	colName := fmt.Sprintf("%s-sumologic-otelagent.%s", release, otelcolInstrumentationNamespace)

	podTemplateSpec := corev1.PodTemplateSpec{
		ObjectMeta: metadata,
		Spec: corev1.PodSpec{
			Containers: optionsToContainers(ctx, options, name, image, colName),
		},
	}
	return appsv1.Deployment{
		ObjectMeta: metadata,
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: appLabels,
			},
			Template: podTemplateSpec,
		},
	}
}

func optionsToContainers(ctx context.Context, options TracesGeneratorOptions, name string, image string, colName string) []corev1.Container {
	// There's no way to tell the log generator to keep running after it's done generating logs. This is annoying if
	// we want to run it in a Deployment and not have it be restarted after exiting. So we sleep after it exits.
	command := fmt.Sprintf("%s; sleep %f", generatorBinaryName, deploymentSleepTime.Seconds())
	return []corev1.Container{
		{
			Name:    name,
			Image:   image,
			Command: []string{"/bin/bash", "-c", "--"},
			Args:    []string{command},
			Env: []corev1.EnvVar{
				{
					Name:  "COLLECTOR_HOSTNAME",
					Value: colName,
				},
				{
					Name:  "TOTAL_TRACES",
					Value: strconv.Itoa(int(options.TracesPerExporter)),
				},
				{
					Name:  "SPANS_PER_TRACE",
					Value: strconv.Itoa(int(options.SpansPerTrace)),
				},
				{
					Name:  "OTLP_HTTP",
					Value: strconv.FormatBool(options.otlpHttpEnabled),
				},
				{
					Name:  "OTLP_GRPC",
					Value: strconv.FormatBool(options.otlpGrpcEnabled),
				},
				{
					Name:  "ZIPKIN",
					Value: strconv.FormatBool(options.zipkinEnabled),
				},
				{
					Name:  "JAEGER_THRIFT_HTTP",
					Value: strconv.FormatBool(options.jaegerThriftHttp),
				},
			},
		},
	}
}
