package helm

const (
	configFileName     = "config.sh"
	yamlDirectory      = "static"
	chartDirectory     = "../../deploy/helm/sumologic"
	chartName          = "sumologic"
	releaseName        = "collection-test"
	defaultNamespace   = "sumologic"
	testDataDirectory  = "./testdata"
	otelConfigFileName = "config.yaml"
)

var subChartNames []string = []string{
	"prometheus",
	"kube-state-metrics",
	"fluent-bit",
	"metrics-server",
	"telegraf-operator",
	"tailing-sidecar",
	"falco",
}
