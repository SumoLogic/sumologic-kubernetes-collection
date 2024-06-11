package stepfuncs

import (
	"context"
	"fmt"
	"strings"
	"testing"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/e2e-framework/klient/k8s"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"

	strings_internal "github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
)

// Option is an interface that is used to pass in types that fulfill it to e.g.
// assess functions in internal/stepfuncs/assess_funcs.go so that their custom
// modification logic can be applied on k8s.Object.
//
// Example:
//
// func WaitUntilStatefulSetIsReady(
//
//	opts ...Option,
//
//	) features.Func {
//	  return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
//	    sts := appsv1.StatefulSet{
//	      ObjectMeta: v1.ObjectMeta{
//	        Namespace: ctxopts.Namespace(ctx),
//	      },
//	    }
//	    for _, opt := range opts {
//	      opt.Apply(ctx, &sts)
//	      ...
//	    }
//	  ...
//	}
type Option interface {
	Apply(ctx context.Context, t *testing.T, obj k8s.Object)
	GetListOption(ctx context.Context, t *testing.T) resources.ListOption
}

// nameOption is an Option that sets a concrete name on the k8s.Object.
type nameOption struct {
	name string
}

func (no nameOption) Apply(ctx context.Context, t *testing.T, obj k8s.Object) {
	obj.SetName(no.name)
}

func (no nameOption) GetListOption(ctx context.Context, t *testing.T) resources.ListOption {
	return func(lo *metav1.ListOptions) {}
}

// WithName creates a nameOption with provided name.
func WithName(name string) Option {
	return nameOption{
		name: name,
	}
}

// nameOption is an Option that allows setting k8s.Object's name using a formatter
// in order to e.g. include value from context that's passed into a running test.
type nameFOption struct {
	formatter Formatter
}

func (no nameFOption) Apply(ctx context.Context, t *testing.T, obj k8s.Object) {
	obj.SetName(no.formatter(ctx, t))
}

func (no nameFOption) GetListOption(ctx context.Context, t *testing.T) resources.ListOption {
	return func(lo *metav1.ListOptions) {
	}
}

// WithNameF creates a nameFOption using the provided formatter.
func WithNameF(formatter Formatter) Option {
	return nameFOption{
		formatter: formatter,
	}
}

type LabelFormatterKV struct {
	K string
	V Formatter
}

type labelsFOption struct {
	kvs []LabelFormatterKV
}

func (lo labelsFOption) Apply(ctx context.Context, t *testing.T, obj k8s.Object) {
	labels := make(map[string]string, len(lo.kvs))
	for _, elem := range lo.kvs {
		labels[elem.K] = elem.V(ctx, t)
	}
	obj.SetLabels(labels)
}

func (lo labelsFOption) GetListOption(ctx context.Context, t *testing.T) resources.ListOption {
	labels := make([]string, 0, len(lo.kvs))
	for _, elem := range lo.kvs {
		labels = append(labels, fmt.Sprintf("%s=%s", elem.K, elem.V(ctx, t)))
	}

	return resources.WithLabelSelector(strings.Join(labels, ","))
}

// WithLabelsF creates an Option which can be used to set key value pairs with
// custom value formatting.
//
// Example:
// stepfuncs.WaitUntilStatefulSetIsReady(
//
//	...
//	stepfuncs.WithLabelsF(
//	  stepfuncs.LabelFormatterKV{
//	    K: "app",
//	    V: stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-events"),
//	  },
//	),
//
// ),
//
// The above snippet will use the helm release name (passed around in tests context)
// and place it in the `%s` format string when a test will be executed.
func WithLabelsF(kvs ...LabelFormatterKV) Option {
	return labelsFOption{
		kvs: kvs,
	}
}

type Formatter func(ctx context.Context, t *testing.T) string

func ReleaseFormatter(format string) Formatter {
	return func(ctx context.Context, t *testing.T) string {
		return fmt.Sprintf(format, strings_internal.ReleaseNameFromT(t))
	}
}
