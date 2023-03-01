package integration

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"testing"
	"time"

	corev1 "k8s.io/api/core/v1"
	log "k8s.io/klog/v2"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/receivermock"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

const (
	tickDuration            = 3 * time.Second
	waitDuration            = 5 * time.Minute
	expectedEventCount uint = 50 // number determined experimentally
	logsGeneratorCount uint = 1000
	logRecords              = 4   // number of log records in single loop, see: tests/integration/yamls/pod_multiline_long_lines.yaml
	logLoops                = 500 // number of loops in which logs are generated, see: tests/integration/yamls/pod_multiline_long_lines.yaml
	multilineLogCount  uint = logRecords * logLoops
	tracesPerExporter  uint = 10 // number of traces generated per exporter
	spansPerTrace      uint = 5
)

func GetMetricsFeature(expectedMetrics []string) features.Feature {
	return features.New("metrics").
		Assess("expected metrics are present",
			stepfuncs.WaitUntilExpectedMetricsPresent(
				expectedMetrics,
				internal.ReceiverMockNamespace,
				internal.ReceiverMockServiceName,
				internal.ReceiverMockServicePort,
				waitDuration,
				tickDuration,
			),
		).
		Assess("expected labels are present",
			// TODO: refactor into a step func?
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				// Get the receiver mock pod as metrics source
				res := envConf.Client().Resources(internal.ReceiverMockNamespace)
				podList := corev1.PodList{}
				require.NoError(t,
					wait.For(
						conditions.New(res).
							ResourceListN(
								&podList,
								1,
								resources.WithLabelSelector("app=receiver-mock"),
							),
						wait.WithTimeout(waitDuration),
						wait.WithInterval(tickDuration),
					),
				)
				rClient, tunnelCloseFunc := receivermock.NewClientWithK8sTunnel(ctx, t)
				defer tunnelCloseFunc()

				assert.Eventually(t, func() bool {
					filters := receivermock.MetadataFilters{
						"__name__": "container_memory_working_set_bytes",
						"pod":      podList.Items[0].Name,
					}
					metricsSamples, err := rClient.GetMetricsSamples(filters)
					if err != nil {
						log.ErrorS(err, "failed getting samples from receiver-mock")
						return false
					}

					if len(metricsSamples) == 0 {
						log.InfoS("got 0 metrics samples", "filters", filters)
						return false
					}

					sort.Sort(receivermock.MetricsSamplesByTime(metricsSamples))
					// For now let's take the newest metric sample only because it will have the most
					// accurate labels and the most labels attached (for instance service/deployment
					// labels might not be attached at the very first record).
					sample := metricsSamples[0]
					labels := sample.Labels
					expectedLabels := receivermock.Labels{
						"cluster":    "kubernetes",
						"_origin":    "kubernetes",
						"container":  "receiver-mock",
						"deployment": "receiver-mock",
						"endpoint":   "https-metrics",
						// TODO: verify the source of label's value.
						// For OTC metadata enrichment this is set to <RELEASE_NAME>-sumologic-otelcol-metrics-<POD_IN_STS_NUMBER>
						// hence with longer time range the time series about a particular metric
						// that we receive diverge into n, where n is the number of metrics
						// enrichment pods.
						"image":                        "",
						"instance":                     "",
						"job":                          "kubelet",
						"metrics_path":                 "/metrics/cadvisor",
						"namespace":                    "receiver-mock",
						"node":                         "",
						"pod_labels_app":               "receiver-mock",
						"pod_labels_pod-template-hash": "",
						"pod_labels_service":           "receiver-mock",
						"pod":                          podList.Items[0].Name,
						"prometheus_replica":           "",
						"prometheus_service":           "",
						"prometheus":                   "",
						"replicaset":                   "",
						"service":                      "receiver-mock",
					}

					log.V(0).InfoS("sample's labels", "labels", labels)
					return labels.MatchAll(expectedLabels)
				}, waitDuration, tickDuration)
				return ctx
			},
		).
		Feature()
}

func GetLogsFeature() features.Feature {
	return features.New("logs").
		Setup(stepfuncs.GenerateLogs(
			stepfuncs.LogsGeneratorDeployment,
			logsGeneratorCount,
			internal.LogsGeneratorName,
			internal.LogsGeneratorNamespace,
			internal.LogsGeneratorImage,
		)).
		Setup(stepfuncs.GenerateLogs(
			stepfuncs.LogsGeneratorDaemonSet,
			logsGeneratorCount,
			internal.LogsGeneratorName,
			internal.LogsGeneratorNamespace,
			internal.LogsGeneratorImage,
		)).
		Assess("logs from log generator deployment present", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"deployment":     internal.LogsGeneratorName,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("logs from log generator daemonset present", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"daemonset":      internal.LogsGeneratorName,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("expected container log metadata is present for log generator deployment", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"cluster": internal.ClusterName,
				// TODO: uncomment this after v4 release
				// or make it depend on the metadata provider
				// "_collector":     internal.ClusterName,
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"container":      internal.LogsGeneratorName,
				"deployment":     internal.LogsGeneratorName,
				"pod":            fmt.Sprintf("%s%s", internal.LogsGeneratorName, internal.PodDeploymentSuffixRegex),
				"host":           internal.NodeNameRegex,
				"node":           internal.NodeNameRegex,
				"_sourceName": fmt.Sprintf(
					"%s\\.%s%s\\.%s",
					internal.LogsGeneratorNamespace,
					internal.LogsGeneratorName,
					internal.PodDeploymentSuffixRegex,
					internal.LogsGeneratorName,
				),
				"_sourceCategory": fmt.Sprintf(
					"%s/%s/%s", // dashes instead of hyphens due to sourceCategoryReplaceDash
					internal.ClusterName,
					strings.ReplaceAll(internal.LogsGeneratorNamespace, "-", "/"),
					strings.ReplaceAll(internal.LogsGeneratorName, "-", "/"), // this is the pod name prefix, in this case the deployment name
				),
				"_sourceHost": internal.EmptyRegex,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("expected container log metadata is present for log generator daemonset", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				// TODO: uncomment this after v4 release
				// or make it depend on the metadata provider
				// "_collector":  "kubernetes",
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"container":      internal.LogsGeneratorName,
				"daemonset":      internal.LogsGeneratorName,
				"pod":            fmt.Sprintf("%s%s", internal.LogsGeneratorName, internal.PodDaemonSetSuffixRegex),
				"host":           internal.NodeNameRegex,
				"node":           internal.NodeNameRegex,
				"_sourceName": fmt.Sprintf(
					"%s\\.%s%s\\.%s",
					internal.LogsGeneratorNamespace,
					internal.LogsGeneratorName,
					internal.PodDaemonSetSuffixRegex,
					internal.LogsGeneratorName,
				),
				"_sourceCategory": fmt.Sprintf(
					"%s/%s/%s", // dashes instead of hyphens due to sourceCategoryReplaceDash
					internal.ClusterName,
					strings.ReplaceAll(internal.LogsGeneratorNamespace, "-", "/"),
					strings.ReplaceAll(internal.LogsGeneratorName, "-", "/"), // this is the pod name prefix, in this case the DaemonSet name
				),
				"_sourceHost": internal.EmptyRegex,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("logs from node systemd present", stepfuncs.WaitUntilExpectedLogsPresent(
			10, // we don't really control this, just want to check if the logs show up
			map[string]string{
				"cluster":         "kubernetes",
				"_sourceName":     internal.NotUndefinedRegex,
				"_sourceCategory": "kubernetes/system",
				"_sourceHost":     internal.NodeNameRegex,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("logs from kubelet present", stepfuncs.WaitUntilExpectedLogsPresent(
			1, // we don't really control this, just want to check if the logs show up
			map[string]string{
				"cluster":         "kubernetes",
				"_sourceName":     "k8s_kubelet",
				"_sourceCategory": "kubernetes/kubelet",
				"_sourceHost":     internal.NodeNameRegex,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Teardown(
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				opts := *ctxopts.KubectlOptions(ctx)
				opts.Namespace = internal.LogsGeneratorNamespace
				terrak8s.RunKubectl(t, &opts, "delete", "deployment", internal.LogsGeneratorName)
				return ctx
			}).
		Teardown(
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				opts := *ctxopts.KubectlOptions(ctx)
				opts.Namespace = internal.LogsGeneratorNamespace
				terrak8s.RunKubectl(t, &opts, "delete", "daemonset", internal.LogsGeneratorName)
				return ctx
			}).
		Teardown(stepfuncs.KubectlDeleteNamespaceOpt(internal.LogsGeneratorNamespace)).
		Feature()

}

func GetMultilineLogsFeature() features.Feature {
	return features.New("multiline logs").
		Setup(stepfuncs.KubectlApplyFOpt(internal.MultilineLogsGenerator, internal.MultilineLogsNamespace)).
		Assess("multiline logs present", stepfuncs.WaitUntilExpectedLogsPresent(
			multilineLogCount,
			map[string]string{
				"namespace":          internal.MultilineLogsNamespace,
				"pod_labels_example": internal.MultilineLogsPodName,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Teardown(stepfuncs.KubectlDeleteFOpt(internal.MultilineLogsGenerator, internal.MultilineLogsNamespace)).
		Feature()
}

func GetEventsFeature() features.Feature {
	return features.New("events").
		Assess("events present", stepfuncs.WaitUntilExpectedLogsPresent(
			expectedEventCount,
			map[string]string{
				"_sourceName":     "events",
				"_sourceCategory": fmt.Sprintf("%s/events", internal.ClusterName),
				"cluster":         "kubernetes",
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Feature()
}

func GetTracesFeature() features.Feature {
	return features.New("traces").
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
}
