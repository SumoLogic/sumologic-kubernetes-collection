package k8s

import (
	"context"
	"testing"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"
	"sigs.k8s.io/e2e-framework/pkg/envconf"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
)

// TunnelForSumologicMock creates a tunnel with port forward to sumologic-mock service.
func TunnelForSumologicMock(
	ctx context.Context,
	envConf *envconf.Config,
	t *testing.T,
	serviceName string,
) *terrak8s.Tunnel {
	kubectlOptions := *ctxopts.KubectlOptions(ctx, envConf)
	kubectlOptions.Namespace = ctxopts.Namespace(ctx)

	tunnel := terrak8s.NewTunnel(
		&kubectlOptions,
		terrak8s.ResourceTypeService,
		serviceName,
		0,
		internal.SumologicMockServicePort,
	)
	tunnel.ForwardPort(t)
	return tunnel
}
