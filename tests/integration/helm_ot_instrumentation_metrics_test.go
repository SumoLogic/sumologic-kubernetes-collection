//go:build allversions
// +build allversions

package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	otoperatorappsv1 "github.com/open-telemetry/opentelemetry-operator/apis/v1alpha1"
	"github.com/stretchr/testify/require"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes/scheme"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
	strings_internal "github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/sumologicmock"
)

// Test_Helm_OT_Instrumentation_Metrics validates that auto-instrumented Python apps
// produce metrics (including histograms) that are received by sumologic-mock via
// the otelcol-instrumentation pipeline with decompose_otlp_histograms enabled.
func Test_Helm_OT_Instrumentation_Metrics(t *testing.T) {

	const (
		tickDuration = time.Second
		waitDuration = time.Minute * 2
	)

	installChecks := []featureCheck{
		CheckSumologicSecret(2),
		CheckTracesWithoutGatewayInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	if err := otoperatorappsv1.AddToScheme(scheme.Scheme); err != nil {
		require.Fail(t, "failed to register scheme: %v", err)
	}

	featOperatorReady := features.New("opentelemetry-operator").
		Assess("opentelemetry-operator deployment is ready", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(ctxopts.Namespace(ctx))
			labelSelector := "app.kubernetes.io/name=opentelemetry-operator"
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
		Assess("instrumentation-cr in test-apps namespace is created", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(internal.InstrumentationAppsNamespace)
			releaseName := strings_internal.ReleaseNameFromT(t)
			labelSelector := fmt.Sprintf("app=%s-sumologic-ot-operator-instr", releaseName)
			instrs := otoperatorappsv1.InstrumentationList{}

			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceListN(&instrs, 1,
							resources.WithLabelSelector(labelSelector),
						),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			return ctx
		}).
		Feature()

	// Deploy the Python metrics test app with auto-instrumentation annotation
	featPythonMetricsApp := features.New("python-metrics-app").
		Setup(stepfuncs.KubectlApplyFOpt(internal.InstrumentationPythonMetricsDep, internal.InstrumentationAppsNamespace)).
		Setup(stepfuncs.KubectlApplyFOpt(internal.InstrumentationPythonMetricsSvc, internal.InstrumentationAppsNamespace)).
		Assess("python-metrics-app deployment is present", stepfuncs.WaitUntilPodsAvailableCustomNS(
			v1.ListOptions{
				LabelSelector: "app=python-metrics-app",
			},
			1,
			waitDuration,
			tickDuration,
			internal.InstrumentationAppsNamespace,
		)).
		Feature()

	// Generate traffic to the Python app to produce metrics
	featTrafficGen := features.New("traffic-generator").WithStep("generate-traffic", features.Level(0),
		stepfuncs.MakeCurl(
			curlAppSleepInterval,
			curlAppMaxWaitTime,
			"metrics-curl-app",
			internal.InstrumentationAppsNamespace,
			internal.CurlAppImage,
		),
	).
		Feature()

	// Verify metrics are received by sumologic-mock
	expectedMetrics := []string{
		"http.server.request.duration",
		"http.server.active_requests",
	}
	expectedHistogramMetrics := []string{
		"http.server.request.duration_bucket",
		"http.server.request.duration_count",
		"http.server.request.duration_sum",
	}

	featMetrics := features.New("instrumentation-metrics").
		Assess("counter and histogram metrics are present",
			stepfuncs.WaitUntilExpectedMetricsPresentWithFilters(
				append(expectedMetrics, expectedHistogramMetrics...),
				sumologicmock.MetadataFilters{
					"service.name": "python-metrics-app",
				},
				false, // don't error on extra metrics
				5*time.Minute,
				tickDuration,
			),
		).
		Feature()

	testenv.Test(t, featInstall, featOperatorReady, featPythonMetricsApp, featTrafficGen, featMetrics)
}
