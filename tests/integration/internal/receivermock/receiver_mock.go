package receivermock

import (
	"crypto/tls"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"testing"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
)

// A HTTP client for the receiver-mock API
type ReceiverMockClient struct {
	baseUrl   url.URL
	tlsConfig tls.Config
	t         *testing.T
}

func NewReceiverMockClient(t *testing.T, baseUrl url.URL) *ReceiverMockClient {
	return &ReceiverMockClient{baseUrl: baseUrl, t: t, tlsConfig: tls.Config{}}
}

func (client *ReceiverMockClient) GetMetricCounts() (map[string]int, error) {
	path, err := url.Parse("metrics-list")
	if err != nil {
		client.t.Fatal(err)
	}
	url := client.baseUrl.ResolveReference(path)

	statusCode, body := http_helper.HttpGet(
		client.t,
		url.String(),
		&client.tlsConfig,
	)
	if statusCode != 200 {
		return nil, fmt.Errorf("received status code %d in response to receiver request", statusCode)
	}
	metricCounts, err := parseMetricList(body)
	if err != nil {
		client.t.Fatal(err)
	}
	return metricCounts, nil
}

// parse metrics list returned by /metrics-list
// https://github.com/SumoLogic/sumologic-kubernetes-tools/tree/main/src/rust/receiver-mock#statistics
func parseMetricList(rawMetricsValues string) (map[string]int, error) {
	metricNameToCount := make(map[string]int)
	lines := strings.Split(rawMetricsValues, "\n")
	for _, line := range lines {
		if len(line) == 0 {
			continue
		}
		// the last colon of the line is the split point
		splitIndex := strings.LastIndex(line, ":")
		if splitIndex == -1 || splitIndex == 0 {
			return nil, fmt.Errorf("failed to parse metrics list line: '%s'", line)
		}
		metricName := line[:splitIndex]
		metricCountString := strings.TrimSpace(line[splitIndex+1:])
		metricCount, err := strconv.Atoi(metricCountString)
		if err != nil {
			return nil, err
		}
		metricNameToCount[metricName] = metricCount
	}
	return metricNameToCount, nil
}
