package k8s

import (
	"context"
	"testing"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
)

// TunnelForReceiverMock creates a tunnel with port forward to receiver-mock service.
func TunnelForReceiverMock(
	ctx context.Context,
	t *testing.T,
) *terrak8s.Tunnel {
	kubectlOptions := *ctxopts.KubectlOptions(ctx)
	kubectlOptions.Namespace = internal.ReceiverMockNamespace

	tunnel := terrak8s.NewTunnel(
		&kubectlOptions,
		terrak8s.ResourceTypeService,
		internal.ReceiverMockServiceName,
		0,
		internal.ReceiverMockServicePort,
	)
	tunnel.ForwardPort(t)
	return tunnel
}
