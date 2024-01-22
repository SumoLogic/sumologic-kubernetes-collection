# Filtering

One of the easiest ways to lower your ingest is to filter out data you do not need. In this guide you will learn how to do this for logs,
metrics and their metadata.

- [OpenTelemetry Collector processors](#opentelemetry-collector-processors)
  - [Filter processor](#filter-processor)
    - [Drop logs on debug level](#drop-logs-on-debug-level)
    - [Drop metric datapoints with unspecified type](#drop-metric-datapoints-with-unspecified-type)
  - [Transform processor](#transform-processor)
    - [Truncate too long attributes](#truncate-too-long-attributes)
    - [Limit to `32` the number of fields sent to Sumo Logic](#limit-the-number-of-fields-sent-to-sumo-logic-to-32)
- [Metadata](#metadata)
  - [Removing unnecessary metadata](#removing-unnecessary-metadata)
  - [Truncating too long attributes](#truncating-too-long-attributes)
  - [Replacing long substring in attributes](#replacing-long-substrings-in-attributes)
- [Logs](#logs)
  - [Excluding logs from specific sources](#excluding-logs-from-specific-sources)
  - [Custom filtering](#custom-filtering)
    - [Shorten log body](#shorten-log-body)
    - [Drop unnecessary logs](#drop-unnecessary-logs)
    - [Drop logs on debug level](#drop-logs-on-debug-level-1)
- [Metrics](#metrics)
  - [Filter out app metrics](#filter-out-app-metrics)
  - [Custom filtering](#custom-filtering-1)
    - [Drop unnecessary metrics](#drop-unnecessary-metrics)
    - [Drop metric datapoints with unspecified type](#drop-metric-datapoints-with-unspecified-type-1)
  - [Prometheus](#prometheus)
    - [Filtering Prometheus metrics by namespace](#filtering-prometheus-metrics-by-namespace)

## OpenTelemetry Collector processors

This Helm Chart uses the OpenTelemetry Collector for data collection and processing. Filtering is accomplished via appropriate Otel
processors such as [Filter processor](#filter-processor) and [Transform processor](#transform-processor).

For logs, you can specify a list of processor definitions under the following keys:

- `sumologic.logs.container.otelcol.extraProcessors` for container logs
- `sumologic.logs.systemd.otelcol.extraProcessors` for systemd logs
- `sumologic.logs.kubelet.otelcol.extraProcessors` for kubelet logs

For metrics, there is a single key:

- `sumologic.metrics.otelcol.extraProcessors`

For example, with this config you can specify two `filter` processors to filter out container logs:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - filter/drop_something:
            ## <filter processor config>
          - filter/drop_something_else:
              ## <filter processor config>
```

And analogously for metrics:

```yaml
sumologic:
  metrics:
    otelcol:
      extraProcessors:
        - filter/drop_something:
          ## <filter processor config>
        - filter/drop_something_else:
            ## <filter processor config>
```

### Filter processor

Filter processor is used to drop telemetry that fulfils specified conditions. Detailed information can be found in the
[processors documentation](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.89.0/processor/filterprocessor). Here
we present some example configs.

#### Drop logs on debug level

```yaml
filter/drop_debug:
  logs:
    log_record:
      - "severity_number >= SEVERITY_NUMBER_DEBUG and severity_number <= SEVERITY_NUMBER_DEBUG4"
```

#### Drop metric datapoints with unspecified type

```yaml
filter/drop_attr:
  metrics:
    datapoint:
      - "type == METRIC_DATA_TYPE_NONE"
```

### Transform processor

Transform processor is used to modify telemetry and metadata. Detailed information can be found in the
[processors documentation](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.89.0/processor/transformprocessor).
Here we present some example configs.

#### Truncate too long attributes

```yaml
transform/truncate:
  log_statements:
    - context: log
      statements:
        - truncate_all(attributes, 4096)
```

#### Limit the number of fields sent to Sumo Logic to `32`

```yaml
## Note: in the Helm Chart we use separate otelcol instances for logs and metrics,
## so you must define separate processors for them in this case.
transform/limit_log_fields:
  log_statements:
    - context: resource
      statements:
        - limit(attributes, 32, [])

transform/limit_metrics_fields:
  metric_statements:
    - context: resource
      statements:
        - limit(attributes, 32, [])
```

## Metadata

This section is common for both logs and metrics.

### Removing unnecessary metadata

To remove metadata you do not want to be sent to Sumo Logic, use [transform processor](#transform-processor) with function `delete_key` or
`delete_matching_keys`:

```yaml
transform/delete_db_endpoint:
  metric_statements:
    ## Delete one resource attribute.
    - context: resource
      statements:
        - delete_key("db.endpoint", attributes)
    ## Delete one metric-level attribute.
    - context: metric
      statements:
        - delete_matching_keys(attributes, "(?i).*password.*")
```

### Truncating too long attributes

If you know that one of the attributes can be very long, you can truncate it using [transform processor](#transform-processor) with function
`set` or `truncate_all`:

```yaml
transform/truncate:
  metric_statements:
    ## Truncate one resource attribute.
    - context: resource
      statements:
        - set(attributes["public_key"], Substring(attributes["public_key"], 0, 255)) where Len(attributes["public_key"]) > 255
    ## Truncate all metric-level attributes.
   - context: metric
     statements:
        - truncate_all(attributes, 255)
```

### Replacing long substrings in attributes

Long substrings can be replaced using [transform processor](#transform-processor) with functions such as `replace_all_matches`,
`replace_all_patterns`, `replace_match`, `replace_pattern`:

```yaml
transform/truncate:
  metric_statements:
    ## Replace regexp pattern in one resource attribute.
    - context: resource
      statements:
        - replace_pattern(attributes["user.password"], "password\\=[^\\s]*(\\s?)", "password=***")
    ## Replace match (https://pkg.go.dev/path/filepath#Match) in all metric-level attributes.
   - context: metric
      statements:
        - replace_all_matches(attributes, "/user/*/list/*", "/user/{userId}/list/{listId}")
```

## Logs

### Excluding logs from specific sources

You can specify regular expressions to exclude collecting logs from specific sources. The logs will be scraped and sent to the metadata
layer, but not forwarded to Sumo Logic.

To specify the expressions, use the following configuration:

```yaml
sumologic:
  logs:
    ## Exclude container logs
    container:
      excludeContainerRegex: "some-log-container-*"
      excludeHostRegex: "some-log-host-*"
      excludeNamespaceRegex: "some-log-namespace-*"
      excludePodRegex: "some-log-pod-*"
    ## Exclude systemd logs
    systemd:
      excludeFacilityRegex: "some-log-facility-*"
      excludeHostRegex: "some-log-host-*"
      excludePriorityRegex: "some-log-priority-*"
      excludeUnitRegex: "some-log-unit-*"
    ## Exclude kubelet logs
    kubelet:
      excludeFacilityRegex: "some-log-facility-*"
      excludeHostRegex: "some-log-host-*"
      excludePriorityRegex: "some-log-priority-*"
      excludeUnitRegex: "some-log-unit-*"
```

### Custom filtering

As [mentioned before](#opentelemetry-collector-processors), you can add custom filtering using OpenTelemetry Collector's processors. Below
are few common examples. Here we present only configs for container logs, but it works the same way for systemd and kubelet logs.

#### Shorten log body

Similarly to [too long attributes](#truncating-too-long-attributes), you can use [transform processor](#transform-processor) to shorten log
body by either truncating it or replacing too long substrings:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - transform/shorten_body:
              log_statements:
                - context: log
                  statements:
                    ## Replace long substring
                    - replace_pattern(body.string, "very_long_key:[0-9A-Za-z]+ENDKEY", "very_long_key:<key>")
                    ## Truncate the body
                    - set(body.string, Substring(body.string, 0, 65535)) where Len(body.string) > 65535
```

#### Drop unnecessary logs

You can use the [filter processor](#filter-processor) to drop logs you don't want to be sent to Sumo Logic:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - filter/postgres_logs:
              logs:
                log_record:
                  ## Drop logs that come from database with name "postgres"
                  - 'resource.attributes["db.name"] == "postgres"'
```

#### Drop logs on debug level

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - filter/drop_debug:
              logs:
                log_record:
                  ## Dropping based on severity number
                  - "severity_number >= SEVERITY_NUMBER_DEBUG and severity_number <= SEVERITY_NUMBER_DEBUG4"
                  ## Dropping based on log body
                  - 'IsMatch(body, ".*DEBUG.*")'
```

## Metrics

### Filter out app metrics

We have defined some default filters to drop app metrics that are not relevant for Sumo Logic dashboards. To enable these filters, add the
following config option to `user_values.yaml`:

```yaml
sumologic:
  metrics:
    enableDefaultFilters: true
```

Full list of metrics affected is available [here](/deploy/helm/sumologic/conf/metrics/otelcol/default-filters.yaml). The metrics listed in
the comments are the metrics that will **not** be dropped.

### Custom filtering

As [mentioned before](#opentelemetry-collector-processors), you can add custom filtering using OpenTelemetry Collector's processors. Below
are few common examples.

#### Drop unnecessary metrics

You can use the [filter processor](#filter-processor) to drop logs you don't want to be sent to Sumo Logic:

```yaml
sumologic:
  metrics:
    otelcol:
      extraProcessors:
        - filter/exclude_sumo_metrics:
            metrics:
              metric:
                ## Exclude all metrics from "sumologic" namespace
                - `resource.attributes["k8s.namespace.name"] == "sumologic"`
```

#### Drop metric datapoints with unspecified type

```yaml
filter/drop_attr:
  metrics:
    datapoint:
      - "type == METRIC_DATA_TYPE_NONE"
```

### Prometheus

You can filter out metrics directly in Prometheus using
[this documentation](https://help.sumologic.com/docs/send-data/kubernetes/collecting-metrics#filtering-metrics).

**Note**: This works only for the deprecated pipeline where Prometheus is used to collect the metrics. If you are using OpenTelemetry
Collector, use other methods to filter out metrics.

#### Filtering Prometheus Metrics by Namespace

If you want to filter metrics by namespace, it can be done in the prometheus remote write config. Here is an example of excluding kube-state
metrics for namespace1 and namespace2:

```yaml
- action: drop
  regex: kube-state-metrics;(namespace1|namespace2)
  sourceLabels: [job, namespace]
```

The section above should be added in each of the kube-state remote write blocks.

Here is another example of excluding up metrics in the sumologic namespace while still collecting up metrics for all other namespaces:

```yaml
# up metrics
- url: http://collection-sumologic.sumologic.svc.cluster.local.:9888/prometheus.metrics
  writeRelabelConfigs:
    - action: keep
      regex: up
      sourceLabels: [__name__]
    - action: drop
      regex: up;sumologic
      sourceLabels: [__name__, namespace]
```

The section above should be added in each of the kube-state remote write blocks.
