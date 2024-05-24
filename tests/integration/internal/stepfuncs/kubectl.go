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

// KubectlCreateOperatorNamespacesOpt returns a features.Func that will create namespaces for sumologic mock.
func KubectlCreateSumologicMockNamespaceOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		namespace := ctxopts.AdditionalSumologicMockNamespace(ctx)
		return KubectlCreateNamespaceOpt(namespace)(ctx, t, envConf)
	}
}

// KubectlDeleteSumologicMockNamespaceOpt returns a features.Func that will delete namespaces for sumologic mock.
func KubectlDeleteSumologicMockNamespaceOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		namespace := ctxopts.AdditionalSumologicMockNamespace(ctx)
		return KubectlDeleteNamespaceOpt(namespace)(ctx, t, envConf)
	}
}

// KubectlCreateOperatorNamespacesOpt returns a features.Func that will create namespaces references by otel operator configuration.
func KubectlCreateOperatorNamespacesOpt() features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		valuesFileBytes := GetHelmValuesForT(t)
		var values struct {
			Operator struct {
				InstrumentationNamespaces string `yaml:"instrumentationNamespaces"`
			} `yaml:"opentelemetry-operator"`
		}

		err := yaml.Unmarshal(valuesFileBytes, &values)
		require.NoError(t, err)
		if values.Operator.InstrumentationNamespaces != "" {
			namespaces := stdstrings.Split(values.Operator.InstrumentationNamespaces, ",")
			for _, namespace := range namespaces {
				k8s.CreateNamespace(t, ctxopts.KubectlOptions(ctx), namespace)
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
			Operator struct {
				InstrumentationNamespaces string `yaml:"instrumentationNamespaces"`
			} `yaml:"opentelemetry-operator"`
		}

		err := yaml.Unmarshal(valuesFileBytes, &values)
		require.NoError(t, err)
		if values.Operator.InstrumentationNamespaces != "" {
			namespaces := stdstrings.Split(values.Operator.InstrumentationNamespaces, ",")
			for _, namespace := range namespaces {
				k8s.DeleteNamespace(t, ctxopts.KubectlOptions(ctx), namespace)
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
			k8s.CreateNamespace(t, ctxopts.KubectlOptions(ctx), values.NamespaceOverride)
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
			k8s.DeleteNamespace(t, ctxopts.KubectlOptions(ctx), values.NamespaceOverride)
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

// Get the content of the Helm values.yaml for the test, as bytes.
func GetHelmValuesForT(t *testing.T) []byte {
	valuesFilePath := path.Join("values", strings.ValueFileFromT(t))
	valuesFileBytes, err := os.ReadFile(valuesFilePath)
	require.NoError(t, err, "values file %s must exist", valuesFilePath)
	return valuesFileBytes
}
