package helm

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestServiceMonitors(t *testing.T) {
	t.Parallel()
	allTemplatePaths := []string{
		"templates/metrics/prometheus/servicemonitors.yaml",
		"charts/kube-prometheus-stack/templates/prometheus/servicemonitors.yaml",
	}

	testCases := []struct {
		Name          string
		ValuesYaml    string
		ExpectedNames []string
		TemplatePaths []string
	}{
		{
			Name: "additionalServiceMonitor",
			ValuesYaml: `
kube-prometheus-stack:
  prometheus:
    enabled: true
    additionalServiceMonitors:
      - name: collection-sumologic-fluentd-logs-test
        additionalLabels:
          sumologic.com/app: fluentd-logs
        endpoints:
          - port: metrics
        namespaceSelector:
          matchNames:
            - $(NAMESPACE)
        selector:
          matchLabels:
            sumologic.com/app: fluentd-logs
            sumologic.com/scrape: "true"
opentelemetry-operator:
  crds:
    create: true
`,
			ExpectedNames: []string{
				"collection-sumologic-otelcol-logs",
				"collection-sumologic-otelcol-metrics",
				"collection-sumologic-metrics-collector",
				"collection-sumologic-otelcol-logs-collector",
				"collection-sumologic-otelcol-events",
				"collection-sumologic-otelcol-traces",
				"collection-sumologic-prometheus",
				"collection-sumologic-fluentd-logs-test",
			},
			TemplatePaths: allTemplatePaths,
		},
		{
			Name: "onlyAdditionalServiceMonitor",
			ValuesYaml: `
kube-prometheus-stack:
  prometheus:
    enabled: true
    additionalServiceMonitors:
      - name: collection-sumologic-fluentd-logs-test
        additionalLabels:
          sumologic.com/app: fluentd-logs
        endpoints:
          - port: metrics
        namespaceSelector:
          matchNames:
            - $(NAMESPACE)
        selector:
          matchLabels:
            sumologic.com/app: fluentd-logs
            sumologic.com/scrape: "true"
opentelemetry-operator:
  crds:
    create: true
sumologic:
  metrics:
    serviceMonitors: []
`,
			ExpectedNames: []string{
				"collection-sumologic-fluentd-logs-test",
			},
			TemplatePaths: allTemplatePaths,
		},
		{
			Name: "default",
			ValuesYaml: `opentelemetry-operator:
  crds:
    create: true`,
			ExpectedNames: []string{
				"collection-sumologic-otelcol-logs",
				"collection-sumologic-otelcol-metrics",
				"collection-sumologic-metrics-collector",
				"collection-sumologic-otelcol-logs-collector",
				"collection-sumologic-otelcol-events",
				"collection-sumologic-otelcol-traces",
				"collection-sumologic-prometheus",
			},
			TemplatePaths: allTemplatePaths,
		},
	}

	for _, tt := range testCases {
		t.Run(tt.Name, func(t *testing.T) {
			names := []string{}
			for _, templatePath := range tt.TemplatePaths {
				servicemonitors := GetServiceMonitors(t, tt.ValuesYaml, templatePath)
				for _, sm := range servicemonitors {
					names = append(names, sm.Name)
				}
			}

			assert.Equal(t, tt.ExpectedNames, names)
		})
	}

}
