package stepfuncs

import (
	"context"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
)

const (
	// envNameHelmNoDependencyUpdate is the name of an environment variable that
	// controls whether to skip the 'helm dependency update' invocation.
	// If its set to anything else than an empty string then it's being skipped.
	envNameHelmNoDependencyUpdate = "HELM_NO_DEPENDENCY_UPDATE"
)

// HelmDependencyUpdateOpt returns a features.Func that will run helm dependency update using
// the provided path as an argument.
//
// NOTE:
// This step will be skipped if the relevant environment variable (envNameHelmNoDependencyUpdate)
// will be set to a non empty value.
func HelmDependencyUpdateOpt(path string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		if os.Getenv(envNameHelmNoDependencyUpdate) != "" {
			t.Logf(
				"Skipping helm dependency update because %s env is set", envNameHelmNoDependencyUpdate,
			)
			return ctx
		}
		helm.RunHelmCommandAndGetOutputE(t, ctxopts.HelmOptions(ctx), "dependency", "update", path)
		return ctx
	}
}

// HelmInstallOpt returns a features.Func that with run helm install using the provided path
// and releaseName as arguments.
//
// NOTE:
// By default the default cluster namespace will be used. If you'd like to specify the namespace
// use SetKubectlNamespaceOpt.
//
func HelmInstallOpt(path string, releaseName string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		helm.Install(t, ctxopts.HelmOptions(ctx), path, releaseName)
		return ctx
	}
}

// HelmDeleteOpt returns a features.Func that with run helm delete using the provided release name
// as argument.
//
// NOTE:
// By default the default cluster namespace will be used. If you'd like to specify the namespace
// use SetKubectlNamespaceOpt.
//
func HelmDeleteOpt(release string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		helm.Delete(t, ctxopts.HelmOptions(ctx), release, true)
		return ctx
	}
}

// KubectlDeleteNamespaceOpt returns a features.Func that with delete the provided namespace.
func KubectlDeleteNamespaceOpt(namespace string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		k8s.DeleteNamespace(t, ctxopts.KubectlOptions(ctx), namespace)
		return ctx
	}
}

// SetKubectlNamespaceOpt returns a features.Func that will create the requested namespace
// in the cluster and set it in kubectlOptions stored in the context.
func SetKubectlNamespaceOpt(namespace string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOptions := ctxopts.KubectlOptions(ctx)
		kubectlOptions.Namespace = namespace
		k8s.CreateNamespace(t, kubectlOptions, namespace)
		return ctx
	}
}

// SetHelmOptionsOpt returns a features.Func that will get the kubectlOptions embedded in the context,
// use it to create helm options with values files set to the provided path.
//
// NOTE:
// By default the default cluster namespace will be used. If you'd like to specify the namespace
// use SetKubectlNamespaceOpt.
//
func SetHelmOptionsOpt(valuesFilePath string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOptions := ctxopts.KubectlOptions(ctx)
		require.NotNil(t, kubectlOptions)

		return ctxopts.WithHelmOptions(ctx, &helm.Options{
			KubectlOptions: kubectlOptions,
			ValuesFiles:    []string{valuesFilePath},
		})
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
