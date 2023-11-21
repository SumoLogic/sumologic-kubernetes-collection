# Filtering

One of the easiest way to lower your ingest is to filter out data you do not need.
In this guide you will learn how to do this for logs, metrics and their metadata.

- [OpenTelemetry Collector processors](#opentelemetry-collector-processors)
  - [Filter processor](#filter-processor)
  - [Transform processor](#transform-processor)
- [Metadata](#metadata)
  - [Removing unnecessary metadata](#removing-unnecessary-metadata)
  - [Truncating too long attributes](#truncating-too-long-attributes)
  - [Replacing long substring in attributes](#replacing-long-substrings-in-attributes)
- [Logs](#logs)
- [Metrics](#metrics)

## OpenTelemetry Collector processors

Basic way to perform any custom filtering is adding additional processors to the pipeline in the metadata layer.

For logs, you can specify a list of config under the following keys:

- `sumologic.logs.container.otelcol.extraProcessors` for container logs
- `sumologic.logs.systemd.otelcol.extraProcessors` for systemd logs
- `sumologic.logs.kubelet.otelcol.extraProcessors` for kubelet logs

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

For metrics, there is a single key `sumologic.metrics.otelcol.extraProcessors`:

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

Filter processor is used to drop telemetry that fulfils specified conditions.
Detailed information can be found in the [processors documentation](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.89.0/processor/filterprocessor).
Here we present some example configs.

Drop logs on debug level:

```yaml
filter/drop_debug:
  logs:
    log_record:
      - 'severity_number >= SEVERITY_NUMBER_DEBUG and severity_number <= SEVERITY_NUMBER_DEBUG4'
```

Drop metric datapoints with unspecified type:

```yaml
filter/drop_attr:
  metrics:
    datapoint:
      - 'type == METRIC_DATA_TYPE_NONE'
```

### Transform processor

Transform processor is used to modify telemetry and metadata.
Detailed information can be found in the [processors documentation](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.89.0/processor/transformprocessor).
Here we present some example configs.

Truncate too long attributes:

```yaml
transform/truncate:
  log_statements:
    - context: log
      statements:
        - truncate_all(attributes, 4096)
```

Limit to `32` the number of fields sent to Sumo Logic:

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

To remove metadata you do not want to be sent to Sumo Logic, use [transform processor](#transform-processor)
with function `delete_key` or `delete_matching_keys`:

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

If you know that one of the attributes can be very long, you can truncate it using [transform processor](#transform-processor)
with function `set` or `truncate_all`:

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

Long substrings can be replaced using [transform processor](#transform-processor) with functions
such as `replace_all_matches`, `replace_all_patterns`, `replace_match`, `replace_pattern`:

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

<!-- todo: existing ways to filter -->

<!-- todo: custom filtering -->

## Metrics

<!-- todo: existing ways to filter -->

<!-- todo: custom filtering -->
