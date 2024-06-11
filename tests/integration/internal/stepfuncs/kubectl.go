package stepfuncs

import (
	"context"
	"os"
	"path"
	stdstrings "strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
)

// KubectlDeleteNamespaceTestOpt wraps KubectlDeleteNamespaceOpt by extracting the
// namespace saved in the context by KubectlCreateNamespaceTestOpt/KubectlCreateNamespaceOpt.
func KubectlDeleteNamespaceTestOpt(force bool) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		namespace := ctxopts.Namespace(ctx)
		kubectlOptions := ctxopts.KubectlOptions(ctx, envConf)
		kubectlOptions.Namespace = ""
		return KubectlDeleteNamespaceOpt(namespace, force)(ctx, t, envConf)
	}
}

// KubectlDeleteNamespaceOpt returns a features.Func that with delete the provided namespace using kubectl options saved in the context.
// If force is set to true, finalizers are ignored during the deletion.
func KubectlDeleteNamespaceOpt(namespace string, force bool) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		var err error
		if force {
			ns := k8s.GetNamespace(t, ctxopts.KubectlOptions(ctx, envConf), namespace)
			client := envConf.Client()
			ns.Spec.Finalizers = []corev1.FinalizerName{}
			err = client.Resources().Update(ctx, ns)
			require.NoError(t, err)
		}
		k8s.DeleteNamespace(t, ctxopts.KubectlOptions(ctx, envConf), namespace)
		return ctx
	}
}

// KubectlCreateNamespaceOpt returns a features.Func that will create the requested namespace
// in the cluster and set it in kubectlOptions stored in the context.
func KubectlCreateNamespaceOpt(namespace string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOptions := ctxopts.KubectlOptions(ctx, envConf)
		k8s.CreateNamespace(t, kubectlOptions, namespace)
		return ctxopts.WithNamespace(ctx, namespace)
	}
}

// KubectlCreateOperatorNamespacesOpt returns a features.Func that will create namespaces references by otel operator configuration.
func KubectlCreateOperatorNamespacesOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		valuesFileBytes := GetHelmValuesForT(t)
		var values struct {
			Instrumentation struct {
				InstrumentationNamespaces string `yaml:"instrumentationNamespaces"`
			} `yaml:"instrumentation"`
		}

		err := yaml.Unmarshal(valuesFileBytes, &values)
		require.NoError(t, err)
		if values.Instrumentation.InstrumentationNamespaces != "" {
			namespaces := stdstrings.Split(values.Instrumentation.InstrumentationNamespaces, ",")
			for _, namespace := range namespaces {
				k8s.CreateNamespace(t, ctxopts.KubectlOptions(ctx, envConf), namespace)
			}
		}
		return ctx
	}
}

// KubectlDeleteOperatorNamespacesOpt returns a features.Func that will delete namespaces references by otel operator configuration.
func KubectlDeleteOperatorNamespacesOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		valuesFileBytes := GetHelmValuesForT(t)
		var values struct {
			Instrumentation struct {
				InstrumentationNamespaces string `yaml:"instrumentationNamespaces"`
			} `yaml:"instrumentation"`
		}

		err := yaml.Unmarshal(valuesFileBytes, &values)
		require.NoError(t, err)
		if values.Instrumentation.InstrumentationNamespaces != "" {
			namespaces := stdstrings.Split(values.Instrumentation.InstrumentationNamespaces, ",")
			for _, namespace := range namespaces {
				ctx = KubectlDeleteNamespaceOpt(namespace, true)(ctx, t, envConf)
			}
		}
		return ctx
	}
}

// KubectlCreateOverrideNamespaceOpt returns a features.Func that will create an override namespace if set in the values.yaml.
func KubectlCreateOverrideNamespaceOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		valuesFileBytes := GetHelmValuesForT(t)
		var values struct {
			NamespaceOverride string `yaml:"namespaceOverride"`
		}

		err := yaml.Unmarshal(valuesFileBytes, &values)
		require.NoError(t, err)
		if values.NamespaceOverride != "" {
			k8s.CreateNamespace(t, ctxopts.KubectlOptions(ctx, envConf), values.NamespaceOverride)
		}
		return ctx
	}
}

// KubectlCreateOverrideNamespaceOpt returns a features.Func that will delete an override namespace if set in the values.yaml.
func KubectlDeleteOverrideNamespaceOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		valuesFileBytes := GetHelmValuesForT(t)
		var values struct {
			NamespaceOverride string `yaml:"namespaceOverride"`
		}

		err := yaml.Unmarshal(valuesFileBytes, &values)
		require.NoError(t, err)
		if values.NamespaceOverride != "" {
			ctx = KubectlDeleteNamespaceOpt(values.NamespaceOverride, true)(ctx, t, envConf)
		}
		return ctx
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
		kubectlOpts := *ctxopts.KubectlOptions(ctx, envConf)
		kubectlOpts.Namespace = namespace
		k8s.KubectlApply(t, &kubectlOpts, yamlPath)
		return ctx
	}
}

// KubectlDeleteFOpt returns a features.Func that will run "kubectl delete -f" in the provided namespace
// with the provided yaml file path as an argument.
func KubectlDeleteFOpt(yamlPath string, namespace string) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOpts := *ctxopts.KubectlOptions(ctx, envConf)
		kubectlOpts.Namespace = namespace
		k8s.KubectlDelete(t, &kubectlOpts, yamlPath)
		return ctx
	}
}

// Get the content of the Helm values.yaml for the test, as bytes.
func GetHelmValuesForT(t *testing.T) []byte {
	valuesFilePath := path.Join("values", strings.ValueFileFromT(t))
	valuesFileBytes, err := os.ReadFile(valuesFilePath)
	require.NoError(t, err, "values file %s must exist", valuesFilePath)
	return valuesFileBytes
}
