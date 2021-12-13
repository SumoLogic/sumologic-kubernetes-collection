package stepfuncs

import (
	"context"
	"testing"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
)

// PrintClusterStateOpt returns a features.Func that will log the output of kubectl get all if the test
// has failed of if the optional force flag has been set.
//
// NOTE:
// By default the default cluster namespace will be used. If you'd like to specify the namespace
// use SetKubectlNamespaceOpt.
//
func PrintClusterStateOpt(force ...bool) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		if (len(force) == 1 && force[0]) || t.Failed() {
			k8s.RunKubectl(t, ctxopts.KubectlOptions(ctx), "get", "all")
			k8s.RunKubectl(t, ctxopts.KubectlOptions(ctx), "get", "events")
		}

		return ctx
	}
}
