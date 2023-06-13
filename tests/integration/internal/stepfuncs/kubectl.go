package stepfuncs

import (
	"context"
	"testing"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
)

// KubectlDeleteNamespaceTestOpt wraps KubectlDeleteNamespaceOpt by extracting the
// namespace saved in the context by KubectlCreateNamespaceTestOpt/KubectlCreateNamespaceOpt.
func KubectlDeleteNamespaceTestOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		namespace := ctxopts.Namespace(ctx)
		return KubectlDeleteNamespaceOpt(namespace)(ctx, t, envConf)
	}
}

// KubectlDeleteNamespaceOpt returns a features.Func that with delete the namespace
// that was saved in context using KubectlSetNamespaceOpt or KubectlSetTestNamespaceOpt.
func KubectlDeleteNamespaceOpt(namespace string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		k8s.DeleteNamespace(t, ctxopts.KubectlOptions(ctx), namespace)
		return ctx
	}
}

// KubectlCreateNamespaceOpt returns a features.Func that will create the requested namespace
// in the cluster and set it in kubectlOptions stored in the context.
func KubectlCreateNamespaceOpt(namespace string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOptions := ctxopts.KubectlOptions(ctx)
		kubectlOptions.Namespace = namespace
		k8s.CreateNamespace(t, kubectlOptions, namespace)
		return ctxopts.WithNamespace(ctx, namespace)
	}
}

// KubectlCreateNamespaceTestOpt wraps KubectlCreateNamespaceOpt by generating
// a namespace name for test.
func KubectlCreateNamespaceTestOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		name := strings.NamespaceFromT(t)
		return KubectlCreateNamespaceOpt(name)(ctx, t, envConf)
	}
}

// KubectlApplyFOpt returns a features.Func that will run "kubectl apply -f" in the provided namespace
// with the provided yaml file path as an argument.
func KubectlApplyFOpt(yamlPath string, namespace string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOpts := *ctxopts.KubectlOptions(ctx)
		kubectlOpts.Namespace = namespace
		k8s.KubectlApply(t, &kubectlOpts, yamlPath)
		return ctx
	}
}

// KubectlDeleteFOpt returns a features.Func that will run "kubectl delete -f" in the provided namespace
// with the provided yaml file path as an argument.
func KubectlDeleteFOpt(yamlPath string, namespace string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOpts := *ctxopts.KubectlOptions(ctx)
		kubectlOpts.Namespace = namespace
		k8s.KubectlDelete(t, &kubectlOpts, yamlPath)
		return ctx
	}
}