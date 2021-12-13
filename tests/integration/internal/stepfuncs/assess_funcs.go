package stepfuncs

import (
	"context"
	"net/url"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	k8s_internal "github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/k8s"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/receivermock"
)

// WaitUntilPodsAvailable returns a features.Func that can be used in `Assess` calls.
// It will wait until the selected pods are available, using the provided total
// `wait` and `tick` times as well as the provided list options and the desired count.
func WaitUntilPodsAvailable(listOptions v1.ListOptions, count int, wait time.Duration, tick time.Duration) features.Func {
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
		k8s.WaitUntilServiceAvailable(t, &kubectlOpts, receiverMockServiceName, int(waitDuration), tickDuration)
		tunnel := k8s.NewTunnel(
			&kubectlOpts,
			k8s.ResourceTypeService,
			receiverMockServiceName,
			0,
			receiverMockServicePort,
		)
		defer tunnel.Close()
		tunnel.ForwardPort(t)
		baseUrl := url.URL{
			Scheme: "http",
			Host:   tunnel.Endpoint(),
			Path:   "/",
		}
		client := receivermock.NewReceiverMockClient(t, baseUrl)
		require.Eventually(t, func() bool {
			metricCounts, err := client.GetMetricCounts(t)
			if err != nil {
				t.Log(err)
				return false
			}
			for _, expectedMetricName := range expectedMetrics {
				_, ok := metricCounts[expectedMetricName]
				if !ok {
					t.Logf("Couldn't find metric %q in %v", expectedMetricName, metricCounts)
					return false
				}
			}
			return true
		}, waitDuration, tickDuration)
		return ctx
	}
}
