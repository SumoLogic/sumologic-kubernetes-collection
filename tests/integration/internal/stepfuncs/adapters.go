package stepfuncs

import (
	"context"
	"testing"

	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func IntoTestEnvFunc(stepFn features.Func) internal.TestEnvFunc {
	return func(ctx context.Context, e *envconf.Config, t *testing.T) (context.Context, error) {
		return stepFn(ctx, t, e), nil
	}
}

func IntoTestEnvFuncs(stepFns ...features.Func) []internal.TestEnvFunc {
	ret := make([]internal.TestEnvFunc, 0, len(stepFns))
	for _, fn := range stepFns {
		fn := fn
		ret = append(ret,
			func(ctx context.Context, e *envconf.Config, t *testing.T) (context.Context, error) {
				return fn(ctx, t, e), nil
			},
		)
	}

	return ret
}
