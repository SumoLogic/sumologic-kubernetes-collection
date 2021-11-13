package main

import (
	"context"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
)

const (
	// envNameHelmNoDependencyUpdate is the name of an environment variable that
	// controls whether to skip the 'helm dependency update' invocation.
	// If its set to anything else than an empty string then it's being skipped.
	envNameHelmNoDependencyUpdate = "HELM_NO_DEPENDENCY_UPDATE"
)

// helmDependencyUpdate runs helm dependency update using the provided path as
// an argument.
func helmDependencyUpdate(path string) func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		if os.Getenv(envNameHelmNoDependencyUpdate) != "" {
			t.Logf(
				"Skipping helm dependency update because %s env is set", envNameHelmNoDependencyUpdate,
			)
			return ctx
		}
		helm.RunHelmCommandAndGetOutputE(t, HelmOptions(ctx), "dependency", "update", path)
		return ctx
	}
}

// helmInstall runs helm install using the provided path and releaseName as arguments.
func helmInstall(path string, releaseName string) func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		helm.Install(t, HelmOptions(ctx), path, releaseName)
		return ctx
	}
}
