package helm

const (
	configFileName           = "config.sh"
	yamlDirectory            = "static"
	chartDirectory           = "../../deploy/helm/sumologic"
	chartName                = "sumologic"
	releaseName              = "collection-test"
	defaultNamespace         = "sumologic"
	testDataDirectory        = "./testdata"
	otelConfigFileName       = "config.yaml"
	otelImageFIPSSuffix      = "-fips"
	otelContainerName        = "otelcol"
	maxHelmReleaseNameLength = 19  // Helm allows up to 53, this is our own limit
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
