package k8s

import (
	"context"
	"testing"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
)

// TunnelForSumologicMock creates a tunnel with port forward to sumologic-mock service.
func TunnelForSumologicMock(
	ctx context.Context,
	t *testing.T,
	serviceName string,
) *terrak8s.Tunnel {
	kubectlOptions := *ctxopts.KubectlOptions(ctx)
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
