package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/e2e-framework/klient/k8s"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"
)

func Test_Helm_Otelcol_Traces(t *testing.T) {
	const (
		tickDuration           = 3 * time.Second
		waitDuration           = 3 * time.Minute
		tracesPerExporter uint = 10 // number of traces generated per exporter
		spansPerTrace     uint = 5
	)
	featInstall := features.New("traces").
		Assess("sumologic secret is created with endpoints",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				terrak8s.WaitUntilSecretAvailable(t, ctxopts.KubectlOptions(ctx), "sumologic", 60, tickDuration)
				secret := terrak8s.GetSecret(t, ctxopts.KubectlOptions(ctx), "sumologic")
				require.Len(t, secret.Data, 2, "Secret has incorrect number of endpoints. There should be 2 endpoints.")
				return ctx
			}).
		// TODO: Rewrite into similar step func as WaitUntilStatefulSetIsReady but for deployments
		Assess("otelcol deployment is ready", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(ctxopts.Namespace(ctx))
			releaseName := ctxopts.HelmRelease(ctx)
			labelSelector := fmt.Sprintf("app=%s-sumologic-otelcol", releaseName)
			ds := appsv1.DeploymentList{}

			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceListN(&ds, 1,
							resources.WithLabelSelector(labelSelector),
						),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			require.NoError(t,
				wait.For(
					conditions.New(res).
						DeploymentConditionMatch(&ds.Items[0], appsv1.DeploymentAvailable, corev1.ConditionTrue),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			return ctx
		}).
		// TODO: Rewrite into similar step func as WaitUntilStatefulSetIsReady but for daemonsets
		Assess("otelagent daemonset is ready", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(ctxopts.Namespace(ctx))
			nl := corev1.NodeList{}
			if !assert.NoError(t, res.List(ctx, &nl)) {
				return ctx
			}

			releaseName := ctxopts.HelmRelease(ctx)
			labelSelector := fmt.Sprintf("app=%s-sumologic-otelagent", releaseName)
			ds := appsv1.DaemonSetList{}

			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceListN(&ds, 1,
							resources.WithLabelSelector(labelSelector),
						),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceMatch(&ds.Items[0], func(object k8s.Object) bool {
							d := object.(*appsv1.DaemonSet)
							return d.Status.NumberUnavailable == 0 &&
								d.Status.NumberReady == int32(len(nl.Items))
						}),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			return ctx
		}).Feature()

	featTraces := features.New("traces").
		Setup(stepfuncs.GenerateTraces(
			tracesPerExporter,
			spansPerTrace,
			internal.TracesGeneratorName,
			internal.TracesGeneratorNamespace,
			internal.TracesGeneratorImage,
		)).
		Assess("wait for otlp http traces", stepfuncs.WaitUntilExpectedTracesPresent(
			tracesPerExporter,
			spansPerTrace,
			map[string]string{
				"__name__":            "root-span-otlpHttp",
				"service.name":        "customer-trace-test-service",
				"_collector":          "kubernetes",
				"k8s.cluster.name":    "kubernetes",
				"k8s.container.name":  internal.TracesGeneratorName,
				"k8s.deployment.name": internal.TracesGeneratorName,
				"k8s.namespace.name":  internal.TracesGeneratorNamespace,
				"k8s.pod.pod_name":    internal.TracesGeneratorName,
				"k8s.pod.label.app":   internal.TracesGeneratorName,
				// "_sourceCategory":    "kubernetes/customer/trace/tester/customer/trace/tester",
				"_sourceName": fmt.Sprintf("%s.%s.%s", internal.TracesGeneratorNamespace, internal.TracesGeneratorName, internal.TracesGeneratorName),
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("wait for otlp grpc traces", stepfuncs.WaitUntilExpectedTracesPresent(
			tracesPerExporter,
			spansPerTrace,
			map[string]string{
				"__name__":            "root-span-otlpGrpc",
				"service.name":        "customer-trace-test-service",
				"_collector":          "kubernetes",
				"k8s.cluster.name":    "kubernetes",
				"k8s.container.name":  internal.TracesGeneratorName,
				"k8s.deployment.name": internal.TracesGeneratorName,
				"k8s.namespace.name":  internal.TracesGeneratorNamespace,
				"k8s.pod.pod_name":    internal.TracesGeneratorName,
				"k8s.pod.label.app":   internal.TracesGeneratorName,
				// "_sourceCategory":    "kubernetes/customer/trace/tester/customer/trace/tester",
				"_sourceName": fmt.Sprintf("%s.%s.%s", internal.TracesGeneratorNamespace, internal.TracesGeneratorName, internal.TracesGeneratorName),
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("wait for zipkin traces", stepfuncs.WaitUntilExpectedTracesPresent(
			tracesPerExporter,
			spansPerTrace,
			map[string]string{
				"__name__":            "root-span-zipkin",
				"service.name":        "customer-trace-test-service",
				"_collector":          "kubernetes",
				"k8s.cluster.name":    "kubernetes",
				"k8s.container.name":  internal.TracesGeneratorName,
				"k8s.deployment.name": internal.TracesGeneratorName,
				"k8s.namespace.name":  internal.TracesGeneratorNamespace,
				"k8s.pod.pod_name":    internal.TracesGeneratorName,
				"k8s.pod.label.app":   internal.TracesGeneratorName,
				// "_sourceCategory":    "kubernetes/customer/trace/tester/customer/trace/tester",
				"_sourceName": fmt.Sprintf("%s.%s.%s", internal.TracesGeneratorNamespace, internal.TracesGeneratorName, internal.TracesGeneratorName),
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("wait for jaeger thrift http traces", stepfuncs.WaitUntilExpectedTracesPresent(
			tracesPerExporter,
			spansPerTrace,
			map[string]string{
				"__name__":            "root-span-jaegerThriftHttp",
				"service.name":        "customer-trace-test-service",
				"_collector":          "kubernetes",
				"k8s.cluster.name":    "kubernetes",
				"k8s.container.name":  internal.TracesGeneratorName,
				"k8s.deployment.name": internal.TracesGeneratorName,
				"k8s.namespace.name":  internal.TracesGeneratorNamespace,
				"k8s.pod.pod_name":    internal.TracesGeneratorName,
				"k8s.pod.label.app":   internal.TracesGeneratorName,
				// "_sourceCategory":    "kubernetes/customer/trace/tester/customer/trace/tester",
				"_sourceName":       fmt.Sprintf("%s.%s.%s", internal.TracesGeneratorNamespace, internal.TracesGeneratorName, internal.TracesGeneratorName),
				"otel.library.name": "jaegerThriftHttp",
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("wait for all spans", stepfuncs.WaitUntilExpectedSpansPresent(
			4*tracesPerExporter*spansPerTrace, // there are 4 exporters
			map[string]string{},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Teardown(func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			opts := *ctxopts.KubectlOptions(ctx)
			opts.Namespace = internal.TracesGeneratorNamespace
			terrak8s.RunKubectl(t, &opts, "delete", "deployment", internal.TracesGeneratorName)
			return ctx
		}).
		Teardown(stepfuncs.KubectlDeleteNamespaceOpt(internal.TracesGeneratorNamespace)).
		Feature()

	testenv.Test(t, featInstall, featTraces)
}
