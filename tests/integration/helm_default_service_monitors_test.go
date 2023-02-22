package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
	"github.com/stretchr/testify/require"
	"k8s.io/client-go/kubernetes/scheme"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"
	promv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"

	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"
)

func Test_Helm_Default_Service_Monitors(t *testing.T) {
	const (
		tickDuration   = 3 * time.Second
		waitDuration   = 5 * time.Minute
		scrapeLabel    = "sumologic.com/scrape"
		componentLabel = "sumologic.com/component"
		appLabel       = "sumologic.com/app"
		eventsAppLabel = "otelcol-events"
	)

	if err := promv1.AddToScheme(scheme.Scheme); err != nil {
		require.Fail(t, "failed to register scheme: %v", err)
	}

	expectedDefaultServiceMonitors := internal.DefaultExpectedSumoServiceMonitors

	featServiceMonitors := features.New("sumo service monitors number").
		Assess("number of service monitors created", stepfuncs.WaitForSumoServiceMonitorCount(expectedDefaultServiceMonitors, waitDuration, tickDuration)).
		Feature()

	featServiceMonitorsSelectors := features.New("sumo service monitors present").
		Assess("collection-sumologic-fluentd-logs",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-fluentd-logs",
				features.Labels{appLabel: "fluentd-logs", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-sumologic-otelcol-logs",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-otelcol-logs",
				features.Labels{appLabel: "fluentd-logs", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-sumologic-fluentd-metrics",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-fluentd-metrics",
				features.Labels{appLabel: "fluentd-metrics", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-sumologic-otelcol-metrics",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-otelcol-metrics",
				features.Labels{appLabel: "fluentd-metrics", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-sumologic-fluentd-events",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-fluentd-events",
				features.Labels{appLabel: "fluentd-events", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-fluent-bit",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-fluent-bit",
				features.Labels{"app.kubernetes.io/name": "fluent-bit", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-sumologic-otelcol-logs-collector",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-otelcol-logs-collector",
				features.Labels{appLabel: "otelcol-logs-collector", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-sumologic-otelcol-events",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-otelcol-events",
				features.Labels{appLabel: "otelcol-events", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-sumologic-otelcol-traces",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-otelcol-traces",
				features.Labels{componentLabel: "instrumentation", scrapeLabel: "true"},
				waitDuration, tickDuration)).
		Assess("collection-sumologic-prometheus",
			stepfuncs.WaitUntilServiceMonitorPresent("collection-sumologic-prometheus",
				features.Labels{"operated-prometheus": "true"},
				waitDuration, tickDuration)).
		Feature()

	featInstrumentationServiceMonitorsLabels := features.New("instrumentation services contain scrape labels").
		Assess("otelagent service scrape labels are present", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			name := fmt.Sprintf("%s-sumologic-otelagent", ctxopts.HelmRelease(ctx))
			service := terrak8s.GetService(t, ctxopts.KubectlOptions(ctx), name)
			require.Equal(t, "true", service.Labels[scrapeLabel])
			require.Equal(t, "instrumentation", service.Labels[componentLabel])
			return ctx
		}).
		Assess("traces-gateway service scrape labels are present", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			name := fmt.Sprintf("%s-sumologic-traces-gateway", ctxopts.HelmRelease(ctx))
			service := terrak8s.GetService(t, ctxopts.KubectlOptions(ctx), name)
			require.Equal(t, "true", service.Labels[scrapeLabel])
			require.Equal(t, "instrumentation", service.Labels[componentLabel])
			return ctx
		}).
		Assess("traces-sampler service scrape labels are present", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			name := fmt.Sprintf("%s-sumologic-traces-sampler-headless", ctxopts.HelmRelease(ctx))
			service := terrak8s.GetService(t, ctxopts.KubectlOptions(ctx), name)
			require.Equal(t, "true", service.Labels[scrapeLabel])
			require.Equal(t, "instrumentation", service.Labels[componentLabel])
			return ctx
		}).
		Feature()

	featPrometheusOperatedServiceMonitorLabels := features.New("instrumentation services contain scrape labels").
		Assess("otelagent service scrape labels are present", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			name := "prometheus-operated"
			service := terrak8s.GetService(t, ctxopts.KubectlOptions(ctx), name)
			require.Equal(t, "true", service.Labels["operated-prometheus"])
			return ctx
		}).
		Feature()

	featEventsServiceMonitorLabels := features.New("otelcol-events service contain scrape labels").
		Assess("otelcol-events service scrape labels are present", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			name := fmt.Sprintf("%s-sumologic-otelcol-events", ctxopts.HelmRelease(ctx))
			service := terrak8s.GetService(t, ctxopts.KubectlOptions(ctx), name)
			require.Equal(t, "otelcol-events", service.Labels[appLabel])
			require.Equal(t, "true", service.Labels[scrapeLabel])
			return ctx
		}).
		Feature()

	featLogsServiceMonitorLabels := features.New("otelcol-logs-collector service contain scrape labels").
		Assess("otelcol-logs-collector service scrape labels are present", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			name := fmt.Sprintf("%s-sumologic-otelcol-logs-collector", ctxopts.HelmRelease(ctx))
			service := terrak8s.GetService(t, ctxopts.KubectlOptions(ctx), name)
			require.Equal(t, "otelcol-logs-collector", service.Labels[appLabel])
			require.Equal(t, "true", service.Labels[scrapeLabel])
			return ctx
		}).
		Feature()

	featMetadataServiceMonitorLabels := features.New("metadata-metrics service contain scrape labels").
		Assess("metadata-metrics service scrape labels are present", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			name := fmt.Sprintf("%s-sumologic-metadata-metrics", ctxopts.HelmRelease(ctx))
			service := terrak8s.GetService(t, ctxopts.KubectlOptions(ctx), name)
			require.Equal(t, "fluentd-metrics", service.Labels[appLabel])
			require.Equal(t, "true", service.Labels[scrapeLabel])
			return ctx
		}).
		Assess("metadata-logs service scrape labels are present", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			name := fmt.Sprintf("%s-sumologic-metadata-logs", ctxopts.HelmRelease(ctx))
			service := terrak8s.GetService(t, ctxopts.KubectlOptions(ctx), name)
			require.Equal(t, "fluentd-logs", service.Labels[appLabel], "scrape label to equal true")
			require.Equal(t, "true", service.Labels[scrapeLabel], "scrape label to be true")
			return ctx
		}).
		Feature()

	testenv.Test(t, featServiceMonitors, featServiceMonitorsSelectors, featInstrumentationServiceMonitorsLabels, featPrometheusOperatedServiceMonitorLabels,
		featEventsServiceMonitorLabels, featLogsServiceMonitorLabels, featMetadataServiceMonitorLabels)
}
