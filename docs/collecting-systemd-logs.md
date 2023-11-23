# Collecting Systemd Logs

<!-- TOC -->

- [Collecting Systemd Logs](#collecting-systemd-logs)
  - [Configuration](#configuration)
    - [Setting source name and other built-in metadata](#setting-source-name-and-other-built-in-metadata)
    - [Filtering](#filtering)
    - [Modifying log records](#modifying-log-records)
      - [Adding custom fields](#adding-custom-fields)
    - [Persistence](#persistence)
  - [Advanced Configuration](#advanced-configuration)
    - [Direct configuration](#direct-configuration)
    - [Disabling systemd logs](#disabling-systemd-logs)

<!-- /TOC -->

By default, log collection is enabled. This includes both container logs and systemd logs. This document covers systemd logs.

Systemd logs are read and parsed directly from the Node journal. They are then sent to a metadata enrichment service which takes care of
custom processing, filtering, and finally sending the data to Sumo Logic. Both the collection and the metadata enrichment are done by the
OpenTelemetry Collector.

## Configuration

High level configuration for logs is located in [values.yaml][values] under the `sumologic.logs` key. Configuration specific to systemd and
kubelet logs is located under the `sumologic.logs.systemd` and `sumologic.logs.kubelet` keys. Kubelet logs are systemd logs, so they are
covered together in this document.

Configuration specific to the log collector DaemonSet can be found under the `otellogs` key.

Finally, configuration specific to the metadata enrichment StatefulSet can be found under the `metadata.logs` key.

Systemd logs are sent in `json`` format.

### Setting source name and other built-in metadata

It's possible to customize the built-in Sumo Logic metadata (like [source name][source_name] for example) for systemd and kubelet logs:

```yaml
sumologic:
  logs:
    systemd:
      ## Set the _sourceName metadata field in Sumo Logic.
      sourceName: "%{_sourceName}"
      ## Set the _sourceCategory metadata field in Sumo Logic.
      sourceCategory: "system"
      ## Set the prefix, for _sourceCategory metadata.
      sourceCategoryPrefix: "kubernetes/"
      ## Used to replace - with another character.
      sourceCategoryReplaceDash: "/"
    kubelet:
      ## Set the _sourceName metadata field in Sumo Logic.
      sourceName: "k8s_kubelet"
      ## Set the _sourceCategory metadata field in Sumo Logic.
      sourceCategory: "kubelet"
      ## Set the prefix, for _sourceCategory metadata.
      sourceCategoryPrefix: "kubernetes/"
      ## Used to replace - with another character.
      sourceCategoryReplaceDash: "/"
```

As can be seen in the above example, these fields can contain templates of the form `%{field_name}`, where `field_name` is the name of a
resource attribute.

### Filtering

Please see [the doc about filtering data](/docs/filtering.md).

### Modifying log records

To modify log records, use [OpenTelemetry processors][opentelemetry_processors]. Add them to
`sumologic.logs.systemd.otelcol.extraProcessors` or `sumologic.logs.kubelet.otelcol.extraProcessors`.

Here are some examples.

To modify log body, use the [Transform processor][transform_processor_docs]:

```yaml
sumologic:
  logs:
    systemd:
      otelcol:
        extraProcessors:
          - transform/mask-card-numbers-systemd:
              log_statements:
                - context: log
                  statements:
                    - replace_pattern(body.MESSAGE, "card=\\d+", "card=***")
    kubelet:
      otelcol:
        extraProcessors:
          - transform/mask-card-numbers-kubelet:
              log_statements:
                - context: log
                  statements:
                    - replace_pattern(body.MESSAGE, "card=\\d+", "card=***")
```

To modify record attributes, use the [Attributes processor][attributes_processor_docs]:

```yaml
sumologic:
  logs:
    container:
      systemd:
        extraProcessors:
          - attributes/add-new-systemd:
              - action: insert
                key: new_attribute
                value: new_value
      kubelet:
        extraProcessors:
          - attributes/add-new-kubelet:
              - action: insert
                key: new_attribute
                value: new_value
```

To modify resource attributes, use the [Resource processor][resource_processor_docs]:

```yaml
sumologic:
  logs:
    systemd:
      otelcol:
        extraProcessors:
          - resource/add-resource-attribute-systemd:
              attributes:
                - action: insert
                  key: environment
                  value: staging
          - resource/remove-systemd:
              attributes:
                - action: delete
                  key: redundant-attribute
    kubelet:
      otelcol:
        extraProcessors:
          - resource/add-resource-attribute-kubelet:
              attributes:
                - action: insert
                  key: environment
                  value: staging
          - resource/remove-kubelet:
              attributes:
                - action: delete
                  key: redundant-attribute
```

#### Adding custom fields

To add a custom [field][sumo_fields] named `static-field` with value `hardcoded-value` to logs, use the following configuration:

```yaml
sumologic:
  logs:
    systemd:
      otelcol:
        extraProcessors:
          - resource/add-static-field-systemd:
              attributes:
                - action: insert
                  key: static-field
                  value: hardcoded-value
    kubelet:
      otelcol:
        extraProcessors:
          - resource/add-static-field-kubelet:
              attributes:
                - action: insert
                  key: static-field
                  value: hardcoded-value
```

> **Note** Make sure the field is [added in Sumo Logic][sumo_add_fields].

### Persistence

Refer to [Persistance section in Collecting Container Logs](./collecting-container-logs.md#persistence)

## Advanced Configuration

This section covers more advanced ways of configuring logging. Knowledge of OpenTelemetry Collector configuration format and concepts will
be required.

### Direct configuration

Refer to [Direct configuration in Collecting Container Logs](./collecting-container-logs.md#direct-configuration)

### Disabling systemd logs

Systemd logs are collected by default. This can be disabled by setting:

```yaml
sumologic:
  logs:
    systemd:
      enabled: false
```

It also disables kubelet logs, as they are subset of systemd logs.

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
