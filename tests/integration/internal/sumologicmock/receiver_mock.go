package sumologicmock

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"testing"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/k8s"
)

// Mapping of metric names to the number of times the metric was observed
type MetricCounts map[string]int

type SpanId string
type TraceId string

// A HTTP client for the sumologic-mock API
type SumologicMockClient struct {
	baseUrl   url.URL
	tlsConfig tls.Config
}

func NewClient(t *testing.T, baseUrl url.URL) *SumologicMockClient {
	return &SumologicMockClient{baseUrl: baseUrl, tlsConfig: tls.Config{}}
}

// NewClientWithK8sTunnel creates a client for sumologic-mock.
// It return the client itself and a tunnel teardown func which should be called
// by the caller when they're done with it.
func NewClientWithK8sTunnel(
	ctx context.Context,
	t *testing.T,
) (*SumologicMockClient, func()) {
	tunnel := k8s.TunnelForSumologicMock(ctx, t)
	baseUrl := url.URL{
		Scheme: "http",
		Host:   tunnel.Endpoint(),
		Path:   "/",
	}

	return &SumologicMockClient{
			baseUrl:   baseUrl,
			tlsConfig: tls.Config{},
		}, func() {
			tunnel.Close()
		}
}

// GetMetricCounts returns the number of times each metric was received by sumologic-mock
func (client *SumologicMockClient) GetMetricCounts(t *testing.T) (MetricCounts, error) {
	path := parseUrl(t, "metrics-list")
	url := client.baseUrl.ResolveReference(path)

	statusCode, body := http_helper.HttpGet(
		t,
		url.String(),
		&client.tlsConfig,
	)
	if statusCode != 200 {
		return nil, fmt.Errorf("received status code %d in response to receiver request", statusCode)
	}
	metricCounts, err := parseMetricList(body)
	if err != nil {
		t.Fatal(err)
	}
	return metricCounts, nil
}

type MetricSample struct {
	Metric    string  `json:"metric,omitempty"`
	Value     float64 `json:"value,omitempty"`
	Labels    Labels  `json:"labels,omitempty"`
	Timestamp uint64  `json:"timestamp,omitempty"`
}

type MetricsSamplesByTime []MetricSample

func (m MetricsSamplesByTime) Len() int           { return len(m) }
func (m MetricsSamplesByTime) Swap(i, j int)      { m[i], m[j] = m[j], m[i] }
func (m MetricsSamplesByTime) Less(i, j int) bool { return m[i].Timestamp > m[j].Timestamp }

type MetadataFilters map[string]string

// GetMetricSamples returns metric samples received by sumologic-mock that pass
// the provided metadata filter.
// Note that in the filter semantics, empty strings match any value
func (client *SumologicMockClient) GetMetricsSamples(
	metadataFilters MetadataFilters,
) ([]MetricSample, error) {
	path, err := url.Parse("metrics-samples")
	if err != nil {
		return nil, fmt.Errorf("failed parsing metrics-samples url: %w", err)
	}
	u := client.baseUrl.ResolveReference(path)

	q := u.Query()
	for k, v := range metadataFilters {
		q.Add(k, v)
	}
	u.RawQuery = q.Encode()

	resp, err := http.Get(u.String())
	if err != nil {
		return nil, fmt.Errorf("failed fetching %s, err: %w", u, err)
	}

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf(
			"received status code %d in response to receiver request at %q",
			resp.StatusCode, u,
		)
	}

	var metricsSamples []MetricSample
	if err := json.NewDecoder(resp.Body).Decode(&metricsSamples); err != nil {
		return nil, err
	}
	return metricsSamples, nil
}

type LogsCountResponse struct {
	Count uint
}

// GetLogsCount returns the numbers of logs received by sumologic-mock that pass
// the provided metadata filter.
// Note that in the filter semantics, empty strings match any value
func (client *SumologicMockClient) GetLogsCount(t *testing.T, metadataFilters MetadataFilters) (uint, error) {
	path := parseUrl(t, "logs/count")

	queryParams := url.Values{}
	for key, value := range metadataFilters {
		queryParams.Set(key, value)
	}

	url := client.baseUrl.ResolveReference(path)
	url.RawQuery = queryParams.Encode()

	statusCode, body, err := http_helper.HttpGetE(
		t,
		url.String(),
		&client.tlsConfig,
	)
	if err != nil {
		return 0, err
	}
	if statusCode != 200 {
		return 0, fmt.Errorf("received status code %d in response to receiver request", statusCode)
	}

	var response LogsCountResponse
	err = json.Unmarshal([]byte(body), &response)
	if err != nil {
		t.Fatal(err)
	}
	return response.Count, nil
}

type Span struct {
	Name         string  `json:"name,omitempty"`
	Id           SpanId  `json:"id,omitempty"`
	TraceId      TraceId `json:"trace_id,omitempty"`
	ParentSpanId SpanId  `json:"parent_span_id,omitempty"`
	Labels       Labels  `json:"attributes,omitempty"`
}

func (client *SumologicMockClient) GetSpansCount(t *testing.T, metadataFilters MetadataFilters) (uint, error) {
	path := parseUrl(t, "spans-list")

	queryParams := url.Values{}
	for key, value := range metadataFilters {
		queryParams.Set(key, value)
	}

	url := client.baseUrl.ResolveReference(path)
	url.RawQuery = queryParams.Encode()

	resp, err := http.Get(url.String())
	if err != nil {
		return 0, fmt.Errorf("failed fetching %s, err: %w", url, err)
	}

	if resp.StatusCode != 200 {
		return 0, fmt.Errorf(
			"received status code %d in response to receiver request at %q",
			resp.StatusCode, url,
		)
	}

	var spans []Span
	if err := json.NewDecoder(resp.Body).Decode(&spans); err != nil {
		return 0, err
	}
	return uint(len(spans)), nil
}

func (client *SumologicMockClient) GetTracesCounts(t *testing.T, metadataFilters MetadataFilters) ([]uint, error) {
	path := parseUrl(t, "traces-list")

	queryParams := url.Values{}
	for key, value := range metadataFilters {
		queryParams.Set(key, value)
	}

	url := client.baseUrl.ResolveReference(path)
	url.RawQuery = queryParams.Encode()

	resp, err := http.Get(url.String())
	if err != nil {
		return []uint{}, fmt.Errorf("failed fetching %s, err: %w", url, err)
	}

	if resp.StatusCode != 200 {
		return []uint{}, fmt.Errorf(
			"received status code %d in response to receiver request at %q",
			resp.StatusCode, url,
		)
	}

	var traces [][]Span
	if err := json.NewDecoder(resp.Body).Decode(&traces); err != nil {
		return []uint{}, err
	}

	var tracesLengths = make([]uint, len(traces))
	for i := 0; i < len(tracesLengths); i++ {
		tracesLengths[i] = uint(len(traces[i]))
	}
	return tracesLengths, nil
}

// parse metrics list returned by /metrics-list
// https://github.com/SumoLogic/sumologic-kubernetes-tools/tree/main/src/rust/sumologic-mock#statistics
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
			return nil, fmt.Errorf("failed to parse metrics list line: %q", line)
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

func parseUrl(t *testing.T, target string) *url.URL {
	path, err := url.Parse(target)
	if err != nil {
		t.Fatal(err)
	}

	return path
}
