package stepfuncs

import (
	"context"
	"fmt"
	"testing"
	"time"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/stretchr/testify/assert"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	log "k8s.io/klog/v2"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	k8s_internal "github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/k8s"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/receivermock"
)

// WaitUntilPodsAvailable returns a features.Func that can be used in `Assess` calls.
// It will wait until the selected pods are available, using the provided total
// `wait` and `tick` times as well as the provided list options and the desired count.
func WaitUntilPodsAvailable(listOptions metav1.ListOptions, count int, wait time.Duration, tick time.Duration) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		k8s_internal.WaitUntilPodsAvailable(t, ctxopts.KubectlOptions(ctx),
			listOptions, count, wait, tick,
		)
		return ctx
	}
}

// WaitUntilExpectedMetricsPresent returns a features.Func that can be used in `Assess` calls.
// It will wait until all the provided metrics are returned by receiver-mock's HTTP API on
// the provided Service and port, until it succeeds or waitDuration passes.
func WaitUntilExpectedMetricsPresent(
	expectedMetrics []string,
	receiverMockNamespace string,
	receiverMockServiceName string,
	receiverMockServicePort int,
	waitDuration time.Duration,
	tickDuration time.Duration,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOpts := *ctxopts.KubectlOptions(ctx)
		kubectlOpts.Namespace = receiverMockNamespace
		terrak8s.WaitUntilServiceAvailable(t, &kubectlOpts, receiverMockServiceName, int(waitDuration), tickDuration)

		client, closeTunnelFunc := receivermock.NewClientWithK8sTunnel(ctx, t)
		defer closeTunnelFunc()

		retries := int(waitDuration / tickDuration)
		message, err := retry.DoWithRetryE(
			t,
			"WaitUntilExpectedMetricsPresent()",
			retries,
			tickDuration,
			func() (string, error) {
				metricCounts, err := client.GetMetricCounts(t)
				if err != nil {
					return "", err
				}
				for _, expectedMetricName := range expectedMetrics {
					_, ok := metricCounts[expectedMetricName]
					if !ok {
						return "", fmt.Errorf("couldn't find metric %q in received metrics", expectedMetricName)
					}
				}
				return fmt.Sprintf("All expected metrics were received: %v", expectedMetrics), nil
			},
		)
		if err != nil {
			t.Fatal(err)
		}
		t.Log(message)
		return ctx
	}
}

// WaitUntilExpectedMetricsPresent returns a features.Func that can be used in `Assess` calls.
// It will wait until the provided number of logs with the provided labels are returned by receiver-mock's HTTP API on
// the provided Service and port, until it succeeds or waitDuration passes.
func WaitUntilExpectedLogsPresent(
	expectedLogsCount uint,
	expectedLogsMetadata map[string]string,
	receiverMockNamespace string,
	receiverMockServiceName string,
	receiverMockServicePort int,
	waitDuration time.Duration,
	tickDuration time.Duration,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOpts := *ctxopts.KubectlOptions(ctx)
		kubectlOpts.Namespace = receiverMockNamespace
		terrak8s.WaitUntilServiceAvailable(t, &kubectlOpts, receiverMockServiceName, int(waitDuration), tickDuration)

		client, closeTunnelFunc := receivermock.NewClientWithK8sTunnel(ctx, t)
		defer closeTunnelFunc()

		assert.Eventually(t, func() bool {
			logsCount, err := client.GetLogsCount(t, expectedLogsMetadata)
			if err != nil {
				log.ErrorS(err, "failed getting log counts from receiver-mock")
				return false
			}
			if logsCount < expectedLogsCount {
				log.InfoS(
					"received logs, less than expected",
					"received", logsCount,
					"expected", expectedLogsCount,
				)
				return false
			}
			log.InfoS(
				"received enough logs",
				"received", logsCount,
				"expected", expectedLogsCount,
				"metadata", expectedLogsMetadata,
			)
			return true
		}, waitDuration, tickDuration)
		return ctx
	}
}
