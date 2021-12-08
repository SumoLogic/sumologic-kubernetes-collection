package internal

import (
	"context"
	"testing"

	"sigs.k8s.io/e2e-framework/pkg/envconf"
)

type TestEnvFunc = func(context.Context, *envconf.Config, *testing.T) (context.Context, error)
