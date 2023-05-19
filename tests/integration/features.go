package integration

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"testing"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	log "k8s.io/klog/v2"
	"sigs.k8s.io/e2e-framework/klient/k8s"
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

type MetricsCollector string

const (
	tickDuration                        = 3 * time.Second
	waitDuration                        = 1 * time.Minute
	expectedEventCount uint             = 50 // number determined experimentally
	logsGeneratorCount uint             = 1000
	logRecords                          = 4   // number of log records in single loop, see: tests/integration/yamls/pod_multiline_long_lines.yaml
	logLoops                            = 500 // number of loops in which logs are generated, see: tests/integration/yamls/pod_multiline_long_lines.yaml
	multilineLogCount  uint             = logRecords * logLoops
	tracesPerExporter  uint             = 5 // number of traces generated per exporter
	spansPerTrace      uint             = 2
	Prometheus         MetricsCollector = "prometheus"
	Otelcol            MetricsCollector = "otelcol"
)

func GetMetricsFeature(expectedMetrics []string, metricsCollector MetricsCollector) features.Feature {
	return features.New("metrics").
		Assess("expected metrics are present",
			stepfuncs.WaitUntilExpectedMetricsPresent(
				expectedMetrics,
				internal.ReceiverMockNamespace,
				internal.ReceiverMockServiceName,
				internal.ReceiverMockServicePort,
				2*time.Minute, // take longer to account for recording rule metrics
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
					releaseName := ctxopts.HelmRelease(ctx)
					namespace := ctxopts.Namespace(ctx)
					expectedLabels := receivermock.Labels{
						"cluster":                      "kubernetes",
						"_origin":                      "kubernetes",
						"container":                    "receiver-mock",
						"deployment":                   "receiver-mock",
						"endpoint":                     "https-metrics",
						"image":                        "sumologic/kubernetes-tools:.*",
						"job":                          "kubelet",
						"metrics_path":                 "/metrics/cadvisor",
						"namespace":                    "receiver-mock",
						"node":                         internal.NodeNameRegex,
						"pod_labels_app":               "receiver-mock",
						"pod_labels_pod-template-hash": ".+",
						"pod_labels_service":           "receiver-mock",
						"pod":                          podList.Items[0].Name,
						"replicaset":                   "receiver-mock-.*",
						"service":                      "receiver-mock",
					}
					prometheusLabels := receivermock.Labels{
						"instance":           internal.IpWithPortRegex,
						"prometheus_replica": fmt.Sprintf("prometheus-%s-.*-0", releaseName),
						"prometheus":         fmt.Sprintf("%s/%s-.*-prometheus", namespace, releaseName),
						"prometheus_service": fmt.Sprintf("%s-.*-kubelet", releaseName),
					}
					otelcolLabels := receivermock.Labels{
						"http.scheme":         "http.",
						"net.host.name":       internal.IpRegex,
						"net.host.port":       internal.NetworkPortRegex,
						"service.instance.id": internal.IpWithPortRegex,
					}

					if metricsCollector == Prometheus {
						for key, value := range prometheusLabels {
							expectedLabels[key] = value
						}
					} else if metricsCollector == Otelcol {
						for key, value := range otelcolLabels {
							expectedLabels[key] = value
						}
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

type featureCheck func(*features.FeatureBuilder) *features.FeatureBuilder

func GetInstallFeature(installChecks []featureCheck) features.Feature {
	featureBuilder := features.New("installation")
	for _, installCheck := range installChecks {
		featureBuilder = installCheck(featureBuilder)
	}

	return featureBuilder.Feature()
}

func CheckSumologicSecret(endpointCount int) featureCheck {
	return func(builder *features.FeatureBuilder) *features.FeatureBuilder {
		return builder.Assess("sumologic secret is created with endpoints",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				terrak8s.WaitUntilSecretAvailable(t, ctxopts.KubectlOptions(ctx), "sumologic", 60, tickDuration)
				secret := terrak8s.GetSecret(t, ctxopts.KubectlOptions(ctx), "sumologic")
				require.Len(t, secret.Data, endpointCount, "Secret has incorrect number of endpoints")
				return ctx
			})
	}
}

func CheckOtelcolMetadataMetricsInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("otelcol metrics statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-metrics"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-metrics"),
					},
				),
			),
		).
		Assess("otelcol metrics buffers PVCs are created and bound",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				res := envConf.Client().Resources(ctxopts.Namespace(ctx))
				pvcs := corev1.PersistentVolumeClaimList{}
				cond := conditions.
					New(res).
					ResourceListMatchN(&pvcs, 1,
						func(object k8s.Object) bool {
							pvc := object.(*corev1.PersistentVolumeClaim)
							if pvc.Status.Phase != corev1.ClaimBound {
								log.V(0).Infof("PVC %q not bound yet", pvc.Name)
								return false
							}
							return true
						},
						resources.WithLabelSelector(
							fmt.Sprintf("app=%s-sumologic-otelcol-metrics", ctxopts.HelmRelease(ctx)),
						),
					)
				require.NoError(t,
					wait.For(cond,
						wait.WithTimeout(waitDuration),
						wait.WithInterval(tickDuration),
					),
				)
				return ctx
			})
}

func CheckOtelcolMetricsCollectorInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("otelcol metrics collector statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration*2,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-metrics-collector"),
				),
			),
		).
		Assess("otelcol metrics collector buffers PVCs are created and bound",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				res := envConf.Client().Resources(ctxopts.Namespace(ctx))
				pvcs := corev1.PersistentVolumeClaimList{}
				cond := conditions.
					New(res).
					ResourceListMatchN(&pvcs, 1,
						func(object k8s.Object) bool {
							pvc := object.(*corev1.PersistentVolumeClaim)
							if pvc.Status.Phase != corev1.ClaimBound {
								log.V(0).Infof("PVC %q not bound yet", pvc.Name)
								return false
							}
							return true
						},
						resources.WithLabelSelector(
							fmt.Sprintf("app.kubernetes.io/instance=%s.%s-sumologic-metrics", ctxopts.Namespace(ctx), ctxopts.HelmRelease(ctx)),
						),
					)
				require.NoError(t,
					wait.For(cond,
						wait.WithTimeout(waitDuration),
						wait.WithInterval(tickDuration),
					),
				)
				return ctx
			})
}

func CheckOtelcolMetadataLogsInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("otelcol logs statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-logs"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-logs"),
					},
				),
			),
		).
		Assess("otelcol logs buffers PVCs are created and bound",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				res := envConf.Client().Resources(ctxopts.Namespace(ctx))
				pvcs := corev1.PersistentVolumeClaimList{}
				cond := conditions.
					New(res).
					ResourceListMatchN(&pvcs, 1,
						func(object k8s.Object) bool {
							pvc := object.(*corev1.PersistentVolumeClaim)
							if pvc.Status.Phase != corev1.ClaimBound {
								log.V(0).Infof("PVC %q not bound yet", pvc.Name)
								return false
							}
							return true
						},
						resources.WithLabelSelector(
							fmt.Sprintf("app=%s-sumologic-otelcol-logs", ctxopts.HelmRelease(ctx)),
						),
					)
				require.NoError(t,
					wait.For(cond,
						wait.WithTimeout(waitDuration),
						wait.WithInterval(tickDuration),
					),
				)
				return ctx
			})
}

func CheckOtelcolEventsInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("otelcol events statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-events"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-events"),
					},
				),
			),
		).
		Assess("otelcol events buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				namespace := ctxopts.Namespace(ctx)
				releaseName := ctxopts.HelmRelease(ctx)
				kubectlOptions := ctxopts.KubectlOptions(ctx)

				t.Logf("kubeconfig: %s", kubectlOptions.ConfigPath)
				cl, err := terrak8s.GetKubernetesClientFromOptionsE(t, kubectlOptions)
				require.NoError(t, err)

				assert.Eventually(t, func() bool {
					pvcs, err := cl.CoreV1().
						PersistentVolumeClaims(namespace).
						List(ctx, v1.ListOptions{
							LabelSelector: fmt.Sprintf("app=%s-sumologic-otelcol-events", releaseName),
						})
					if !assert.NoError(t, err) {
						return false
					}

					return len(pvcs.Items) == 1
				}, waitDuration, tickDuration)
				return ctx
			})
}

func CheckPrometheusInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("prometheus pod is available",
			stepfuncs.WaitUntilPodsAvailable(
				v1.ListOptions{
					LabelSelector: "app.kubernetes.io/name=prometheus",
				},
				1,
				waitDuration,
				tickDuration,
			),
		)
}

func CheckOtelcolLogsCollectorInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("otelcol daemonset is ready",
			stepfuncs.WaitUntilDaemonSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-logs-collector"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-logs-collector"),
					},
				),
			),
		)

}

func CheckFluentBitInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("fluent-bit daemonset is running",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				var daemonsets []appsv1.DaemonSet
				require.Eventually(t, func() bool {
					daemonsets = terrak8s.ListDaemonSets(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
						LabelSelector: "app.kubernetes.io/name=fluent-bit",
					})

					return len(daemonsets) == 1
				}, waitDuration, tickDuration)

				require.EqualValues(t, 0, daemonsets[0].Status.NumberUnavailable)
				return ctx
			})

}

func CheckTracesInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("traces-sampler deployment is ready",
			stepfuncs.WaitUntilDeploymentIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-traces-gateway"),
				),
				stepfuncs.WithLabelsF(stepfuncs.LabelFormatterKV{
					K: "app",
					V: stepfuncs.ReleaseFormatter("%s-sumologic-traces-gateway"),
				},
				),
			)).
		Assess("otelcol-instrumentation statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-instrumentation"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-instrumentation"),
					},
				),
			),
		).
		Assess("traces-gateway deployment is ready",
			stepfuncs.WaitUntilDeploymentIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-traces-gateway"),
				),
				stepfuncs.WithLabelsF(stepfuncs.LabelFormatterKV{
					K: "app",
					V: stepfuncs.ReleaseFormatter("%s-sumologic-traces-gateway"),
				},
				),
			))

}

func CheckFluentdMetadataLogsInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("fluentd logs statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-logs"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-logs"),
					},
				),
			),
		).
		Assess("fluentd logs buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				namespace := ctxopts.Namespace(ctx)
				releaseName := ctxopts.HelmRelease(ctx)
				kubectlOptions := ctxopts.KubectlOptions(ctx)

				t.Logf("kubeconfig: %s", kubectlOptions.ConfigPath)
				cl, err := terrak8s.GetKubernetesClientFromOptionsE(t, kubectlOptions)
				require.NoError(t, err)

				assert.Eventually(t, func() bool {
					pvcs, err := cl.CoreV1().PersistentVolumeClaims(namespace).
						List(ctx, v1.ListOptions{
							LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-logs", releaseName),
						})
					if !assert.NoError(t, err) {
						return false
					}

					return err == nil && len(pvcs.Items) == 3
				}, waitDuration, tickDuration)
				return ctx
			})
}

func CheckFluentdMetadataMetricsInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("fluentd metrics statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-metrics"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-metrics"),
					},
				),
			),
		).
		Assess("fluentd metrics buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				namespace := ctxopts.Namespace(ctx)
				releaseName := ctxopts.HelmRelease(ctx)
				kubectlOptions := ctxopts.KubectlOptions(ctx)

				t.Logf("kubeconfig: %s", kubectlOptions.ConfigPath)
				cl, err := terrak8s.GetKubernetesClientFromOptionsE(t, kubectlOptions)
				require.NoError(t, err)

				assert.Eventually(t, func() bool {
					pvcs, err := cl.CoreV1().PersistentVolumeClaims(namespace).
						List(ctx, v1.ListOptions{
							LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-metrics", releaseName),
						})
					if !assert.NoError(t, err) {
						return false
					}

					return err == nil && len(pvcs.Items) == 3
				}, waitDuration, tickDuration)
				return ctx
			})
}

func CheckFluentdEventsInstall(builder *features.FeatureBuilder) *features.FeatureBuilder {
	return builder.
		Assess("fluentd events statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-events"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-events"),
					},
				),
			),
		).
		Assess("fluentd events buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				namespace := ctxopts.Namespace(ctx)
				releaseName := ctxopts.HelmRelease(ctx)
				kubectlOptions := ctxopts.KubectlOptions(ctx)

				t.Logf("kubeconfig: %s", kubectlOptions.ConfigPath)
				cl, err := terrak8s.GetKubernetesClientFromOptionsE(t, kubectlOptions)
				require.NoError(t, err)

				assert.Eventually(t, func() bool {
					pvcs, err := cl.CoreV1().PersistentVolumeClaims(namespace).
						List(ctx, v1.ListOptions{
							LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-events", releaseName),
						})
					if !assert.NoError(t, err) {
						return false
					}

					return err == nil && len(pvcs.Items) == 1
				}, waitDuration, tickDuration)
				return ctx
			})
}
