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
	customLabelKey           = "customLabelKey"
	customLabelValue         = "customLabelValue"
	customAnnotationsKey     = "customAnnotationsKey"
	customAnnotationsValue   = "customAnnotationsValue"
	customImagePullSecrets   = "customImagePullSecrets"
	customImagePullSecrets2  = "customImagePullSecrets2"
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

var expectedAnnotations = map[string]string{
	"customServiceAccountAnnotationKey": "customServiceAccountAnnotationValue",
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

var affinity = corev1.Affinity{
	//   affinity:
	//     nodeAffinity:
	//       requiredDuringSchedulingIgnoredDuringExecution:
	//         nodeSelectorTerms:
	//           - matchExpressions:
	//               - key: kubernetes.io/os
	//                 operator: NotIn
	//                 values:
	//                   - linux
	NodeAffinity: &corev1.NodeAffinity{
		RequiredDuringSchedulingIgnoredDuringExecution: &corev1.NodeSelector{
			NodeSelectorTerms: []corev1.NodeSelectorTerm{
				{
					MatchExpressions: []corev1.NodeSelectorRequirement{
						{
							Key:      "kubernetes.io/os",
							Operator: corev1.NodeSelectorOpNotIn,
							Values:   []string{"linux"},
						},
					},
					MatchFields: nil,
				},
			},
		},
	},
	PodAffinity:     nil,
	PodAntiAffinity: nil,
}
