# Collecting Container Logs

<!-- TOC -->

- [Configuration](#configuration)
  - [Multiline log parsing](#multiline-log-parsing)
  - [Setting source name and other built-in metadata](#setting-source-name-and-other-built-in-metadata)
  - [Filtering](#filtering)
  - [Modifying log records](#modifying-log-records)
    - [Adding custom fields](#adding-custom-fields)
  - [Persistence](#persistence)
- [Advanced Configuration](#advanced-configuration)
  - [Direct configuration](#direct-configuration)
  - [Disabling container logs](#disabling-container-logs)
  <!-- /TOC -->

By default, log collection is enabled. This includes both container logs and systemd logs. This document covers container logs.

Container logs are read and parsed directly from the Node filesystem, where the kubelet writes them under the `/var/log/pods` directory.
They are then sent to a metadata enrichment service which takes care of adding Kubernetes metadata, custom processing, filtering, and
finally sending the data to Sumo Logic. Both the collection and the metadata enrichment are done by the OpenTelemetry Collector.

See the [Solution Overview diagram](README.md#log-collection) for a visualisation.

## Configuration

High level configuration for logs is located in [values.yaml][values] under the `sumologic.logs` key. Configuration specific to container
logs is located under the `sumologic.logs.container` key.

Configuration specific to the log collector DaemonSet can be found under the `otellogs` key.

Finally, configuration specific to the metadata enrichment StatefulSet can be found under the `metadata.logs` key.

### Multiline log parsing

By default, each line output by an application is treated as a separate log record. However, some applications can actually output logs
split into multiple lines - this is often the case for stack traces, for example. If we want such a multiline log to appear in Sumo Logic as
a single record, we need to tell the collector how to distinguish between lines which start a new record and ones which continue an existing
record.

Multiline log parsing can be configured using the `sumologic.logs.multiline` section in `user-values.yaml`.

```yaml
sumologic:
  logs:
    multiline:
      enabled: true
      first_line_regex: "^\\[?\\d{4}-\\d{1,2}-\\d{1,2}.\\d{2}:\\d{2}:\\d{2}"
```

where `first_line_regex` is a regular expression used to detect the first line of a multiline log.

This feature is enabled by default and the default regex will catch logs starting with a ISO8601 datetime. For example:

```text
2007-03-01T13:00:00Z this is the first line of a log record
  this is the second line
  and this is the third line
2007-03-01T13:00:01Z this is a new log record
```

This feature can rarely cause problems by merging together lines which are supposed to be separate. In that case, feel free to disable it.

### Log format

There are three log formats available: `fields`, `json_merge` and `text`. `fields` is the default.

You can change it by setting:

```yaml
sumologic:
  logs:
    container:
      format: fields
```

We're going to demonstrate the differences between them on two example log lines:

1. A plain text log

   ```text
   2007-03-01T13:00:00Z I am a log line
   ```

1. A JSON log

   ```json
   { "log_property": "value", "text": "I am a json log" }
   ```

#### `fields` log format

Logs formatted as `fields` are wrapped in a JSON object with additional properties, with the log body residing under the `log` key.

For example, log line 1 will show up in Sumo Logic as:

```javascript
{
  log: "2007-03-01T13:00:00Z I am a log line",
  stream: "stdout",
  timestamp: 1673627100045
}
```

If the log line contains json, as log line 2 does, it will be displayed as a nested object inside the `log` key:

```javascript
{
  log: {
    log_property: "value",
    text: "I am a json log"
  },
  stream: "stdout",
  timestamp: 1673627100045
}
```

#### `json_merge` log format

`json_merge` is identical to `fields` for non-JSON logs, but behaves differently for JSON logs. If the log is JSON, it gets merged into the
top-level object.

Log line 1 will show up the same way as it did for `fields`:

```javascript
{
  log: "2007-03-01T13:00:00Z I am a log line",
  stream: "stdout",
  timestamp: 1673627100045
}
```

However, the attributes from log line 2 will show up at the top level:

```javascript
{
  log: {
    log_property: "value",
    text: "I am a json log"
  },
  stream: "stdout",
  timestamp: 1673627100045
  log_property: "value",
  text: "I am a json log"
}
```

#### `text` log format

The `text` log format sends the log line as-is without any additional wrappers.

Log line 1 will therefore show up as plain text:

```text
2007-03-01T13:00:00Z I am a log line
```

Whereas log line 2 will be displayed as JSON:

```javascript
{
  log_property: "value",
  text: "I am a json log"
}
```

> **Warning** Setting the format to `text` has certain consequences for multiline detection. See [here][troubleshooting_text_format] for
> more details.

### Setting source name and other built-in metadata

It's possible to customize the built-in Sumo Logic metadata (like [source name][source_name] for example) for container logs:

```yaml
sumologic:
  logs:
    container:
      ## Set the _sourceHost metadata field in Sumo Logic.
      sourceHost: ""
      ## Set the _sourceName metadata field in Sumo Logic.
      sourceName: "%{namespace}.%{pod}.%{container}"
      ## Set the _sourceCategory metadata field in Sumo Logic.
      sourceCategory: "%{namespace}/%{pod_name}"
      ## Set the prefix, for _sourceCategory metadata.
      sourceCategoryPrefix: "kubernetes/"
      ## Used to replace - with another character.
      sourceCategoryReplaceDash: "/"
```

As can be seen in the above example, these fields can contain templates of the form `%{field_name}`, where `field_name` is the name of a
resource attribute. Available resource attributes include the values of `sumologic.logs.fields`, which by default are:

- `cluster`
- `container`
- `daemonset`
- `deployment`
- `host`
- `namespace`
- `node`
- `pod`
- `service`
- `statefulset`

in addition to the following:

- `_collector`
- `pod_labels_*` where `*` is the Pod label name

### Filtering

Logs can be excluded based on their container name, pod name, host, and namespace. This is done by providing a matching regular expression:

```yaml
sumologic:
  logs:
    container:
      ## A regular expression for containers.
      ## Matching containers will be excluded from Sumo. The logs will still be sent to logs metadata provider (otelcol).
      excludeContainerRegex: ""
      ## A regular expression for hosts.
      ## Matching hosts will be excluded from Sumo. The logs will still be sent to logs metadata provider (otelcol).
      excludeHostRegex: ""
      ## A regular expression for namespaces.
      ## Matching namespaces will be excluded from Sumo. The logs will still be sent to logs metadata provider (otelcol).
      excludeNamespaceRegex: ""
      ## A regular expression for pods.
      ## Matching pods will be excluded from Sumo. The logs will still be sent to logs metadata provider (otelcol).
      excludePodRegex: ""
```

For more advanced scenarios, use [OpenTelemetry processors][opentelemetry_processors]. Add them to
`sumologic.logs.container.otelcol.extraProcessors`.

Here are some examples:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - filter/include-logs-based-on-resource-attribute:
              logs:
                include:
                  match_type: strict
                  resource_attributes:
                    - key: host.name
                      value: just_this_one_hostname
          - filter/include-logs-based-on-resource-attribute-regex:
              logs:
                include:
                  match_type: regexp
                  resource_attributes:
                    - key: host.name
                      value: prefix.*
          - filter/exclude-healthcheck-logs:
              logs:
                exclude:
                  match_type: regexp
                  bodies:
                    - /healthcheck
```

For more examples and detailed documentation, see [Filter processor docs][filter_processor_docs].

### Modifying log records

To modify log records, use [OpenTelemetry processors][opentelemetry_processors]. Add them to
`sumologic.logs.container.otelcol.extraProcessors`.

Here are some examples.

To modify log body, use the [Transform processor][transform_processor_docs]:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - transform/mask-card-numbers:
              log_statements:
                - context: log
                  statements:
                    - replace_pattern(body, "card=\\d+", "card=***")
```

To modify record attributes, use the [Attributes processor][attributes_processor_docs]:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - attributes/delete-record-attribute:
              actions:
                - action: delete
                  key: unwanted.attribute
          # To rename old.attribute to new.attribute, first create new.attribute and then delete old.attribute.
          - attributes/rename-old-to-new:
              - action: insert
                key: new.attribute
                from_attribute: old.attribute
              - action: delete
                key: old.attribute
```

To modify resource attributes, use the [Resource processor][resource_processor_docs]:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - resource/add-resource-attribute:
              attributes:
                - action: insert
                  key: environment
                  value: staging
          - resource/remove:
              attributes:
                - action: delete
                  key: redundant-attribute
```

#### Adding custom fields

To add a custom [field][sumo_fields] named `static-field` with value `hardcoded-value` to logs, use the following configuration:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - resource/add-static-field:
              attributes:
                - action: insert
                  key: static-field
                  value: hardcoded-value
```

To add a custom field named `k8s_app` with a value that comes from e.g. the pod label `app.kubernetes.io/name`, use the following
configuration:

```yaml
sumologic:
  logs:
    container:
      otelcol:
        extraProcessors:
          - resource/add-k8s_app-field:
              attributes:
                - action: insert
                  key: k8s_app
                  from_attribute: pod_labels_app.kubernetes.io/name
```

> **Note** Make sure the field is [added in Sumo Logic][sumo_add_fields].

### Persistence

By default, the metadata enrichment service provisions and uses a Kubernetes PersistentVolume as an on-disk queue that guarantees durability
across Pod restarts and buffering in case of exporting problems.

This feature is enabled by default, but it only works if you have a correctly configured default `storageClass` in your cluster. Cloud
providers will do this for you when provisioning the cluster. The only alternative is disabling persistence altogether.

Persistence can be customized via the `metadata.logs.persistence` section:

```yaml
metadata:
  persistence:
    enabled: true
    # storageClass: ""
    accessMode: ReadWriteOnce
    size: 10Gi
    ## Add custom labels to all otelcol statefulset PVC (logs and metrics)
    pvcLabels: {}
```

> **Note** These settings affect persistence for metrics as well.

## Advanced Configuration

This section covers more advanced ways of configuring logging. Knowledge of OpenTelemetry Collector configuration format and concepts will
be required.

### Direct configuration

There are two ways of directly configuring OpenTelemetry Collector for both log collection and metadata enrichment. These are both advanced
features requiring a good understanding of this chart's architecture and OpenTelemetry Collector configuration.

The `metadata.logs.config.merge` and `otellogs.config.merge` keys can be used to provide configuration that will be merged with the Helm
Chart's default configuration. It should be noted that this field is not subject to normal backwards compatibility guarantees, the default
configuration can change even in minor versions while preserving the same end-to-end behaviour. Use of this field is discouraged - ideally
the necessary customizations should be able to be achieved without touching the otel configuration directly. Please open an issue if your
use case requires the use of this field.

The `metadata.logs.config.override` and `otellogs.config.override` keys can be used to provide configuration that will be completely replace
the default configuration. As above, care must be taken not to depend on implementation details that may change between minor releases of
this Chart.

See [Sumologic OpenTelemetry Collector configuration][configuration] for more information.

### Disabling container logs

Container logs are collected by default. This can be disabled by setting:

```yaml
sumologic:
  logs:
    container:
      enabled: false
```

[configuration]: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/docs/configuration.md
[values]: /deploy/helm/sumologic/values.yaml
[source_name]: https://help.sumologic.com/docs/send-data/reference-information/metadata-naming-conventions/#Source_Name
[filter_processor_docs]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.69.0/processor/filterprocessor/README.md
[opentelemetry_processors]: https://opentelemetry.io/docs/collector/configuration/#processors
[attributes_processor_docs]:
  https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.69.0/processor/attributesprocessor/README.md
[resource_processor_docs]:
  https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.69.0/processor/resourceprocessor/README.md
[transform_processor_docs]:
  https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.69.0/processor/transformprocessor/README.md
[sumo_fields]: https://help.sumologic.com/docs/manage/fields/
[sumo_add_fields]: https://help.sumologic.com/docs/manage/fields/#add-field
[troubleshooting_text_format]: fluent/troubleshoot-collection.md#using-text-format
