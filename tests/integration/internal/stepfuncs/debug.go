package stepfuncs

import (
	"context"
	"os"
	"os/signal"
	"testing"
	"time"

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
func PrintClusterStateOpt(force ...bool) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		if (len(force) == 1 && force[0]) || t.Failed() {
			kubectlOptions := *ctxopts.KubectlOptions(ctx)
			kubectlOptions.Namespace = ctxopts.Namespace(ctx)
			k8s.RunKubectl(t, &kubectlOptions,
				"logs", "-lapp=sumoloigic-mock", "--tail=1000",
			)

			k8s.RunKubectl(t, ctxopts.KubectlOptions(ctx), "get", "all")
			k8s.RunKubectl(t, ctxopts.KubectlOptions(ctx), "get", "events")
		}

		return ctx
	}
}

// Wait is a step func that will wait for an hour or until a SIGKILL or SIGINT
// will be received.
// It can be used as a helper func in order to inspect cluster state at a particular step.
func Wait() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		ch := make(chan os.Signal, 1)
		signal.Notify(ch, os.Interrupt)
		select {
		case <-time.After(time.Hour):
		case <-ch:
		}
		return ctx
	}
}
