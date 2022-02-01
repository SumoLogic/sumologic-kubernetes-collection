package stepfuncs

import (
	"context"
	"fmt"
	"os"
	"path"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
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
		ctx = ctxopts.WithHelmRelease(ctx, releaseName)

		err := helm.InstallE(t, ctxopts.HelmOptions(ctx), path, releaseName)
		if err != nil {
			// Print setup job logs if installation failed.
			k8s.RunKubectl(t, ctxopts.KubectlOptions(ctx),
				"logs", fmt.Sprintf("-ljob-name=%s-sumologic-setup", releaseName),
			)

			require.NoError(t, err)
		}

		return ctx
	}
}

// HelmInstallTestOpt wraps HelmInstallOpt with helm release name generation for tests.
func HelmInstallTestOpt(path string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		releaseName := strings.ReleaseNameFromT(t)
		return HelmInstallOpt(path, releaseName)(ctx, t, envConf)
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

// HelmDeleteTestOpt wraps HelmDeleteOpt by taking the release name saved in context
// by HelmInstallTestOpt/HelmInstallOpt.
func HelmDeleteTestOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		releaseName := ctxopts.HelmRelease(ctx)
		return HelmDeleteOpt(releaseName)(ctx, t, envConf)
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

// SetHelmOptionsTestOpt wraps SetHelmOptionsOpt by taking the values file from
// `values` directory and concatenating that with a name name generated from a test name.
//
// The details of values file name generation can be found in `strings.ValueFileFromT()`.
func SetHelmOptionsTestOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		valuesFilePath := path.Join("values", strings.ValueFileFromT(t))
		return SetHelmOptionsOpt(valuesFilePath)(ctx, t, envConf)
	}
}
