package helm

import corev1 "k8s.io/api/core/v1"

const (
	configFileName           = "config.sh"
	yamlDirectory            = "static"
	chartDirectory           = "../../deploy/helm/sumologic"
	chartName                = "sumologic"
	releaseName              = "col-test"
	defaultNamespace         = "sumologic"
	defaultK8sVersion        = "1.26.0"
	testDataDirectory        = "./testdata"
	otelConfigFileName       = "config.yaml"
	otelImageFIPSSuffix      = "-fips"
	otelContainerName        = "otelcol"
	nodeSelectorKey          = "disktype"
	nodeSelectorValue        = "hdd"
	maxHelmReleaseNameLength = 22  // Helm allows up to 53, but for a name longer than 22 some statefulset names will be too long
	k8sMaxNameLength         = 253 // see https://kubernetes.io/docs/concepts/overview/working-with-objects/names/
	k8sMaxLabelLength        = 63  // see https://kubernetes.io/docs/concepts/overview/working-with-objects/names/
)

var subChartNames []string = []string{
	"prometheus",
	"kube-state-metrics",
	"fluent-bit",
	"metrics-server",
	"telegraf-operator",
	"tailing-sidecar",
	"falco",
	"opentelemetry-operator",
}

var toleration = corev1.Toleration{
	Key:      "key",
	Value:    "value",
	Operator: corev1.TolerationOpExists,
	Effect:   corev1.TaintEffectNoSchedule,
	// - key: "key"
	// value: "value"
	// operator: Exists
	// effect: "NoSchedule"
}
