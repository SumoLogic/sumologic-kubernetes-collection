# Collecting container logs
<!-- TOC -->
- [Configuration](#configuration)
  - [Multiline log parsing](#multiline-log-parsing)
  - [Setting source name and other built-in metadata](#setting-source-name-and-other-built-in-metadata)
  - [Filtering](#filtering)
  - [Modifying log records](#modifying-log-records)
  - [Persistence](#persistence)
- [Advanced Configuration](#advanced-configuration)
  - [Advanced Filtering](#advanced-filtering)
  - [Disabling container logs](#disabling-container-logs)
<!-- /TOC -->

By default, log collection is enabled. This includes both container logs and systemd logs. This document covers container logs.

Container logs are read and parsed directly from the Node filesystem, where the kubelet writes them under the `/var/log/pods`
directory. They are then sent to a metadata enrichment service which takes care of adding Kubernetes metadata, custom processing,
filtering, and finally sending the data to Sumo Logic. Both the collection and the metadata enrichment are done by the OpenTelemetry Collector.

See the [Solution Overview diagram](README.md#log-collection) for a visualisation.

## Configuration

High level  configuration for logs is located in [`values.yaml`][values] under the `sumologic.logs` key. Configuration
specific to container logs is located under the `sumologic.logs.container` key.

Configuration specific to the log collector DaemonSet can be found under the `otellogs` key.

Finally, configuration specific to the metadata enrichment StatefulSet can be found under the `metadata.logs` key.

### Multiline log parsing

By default, each line output by an application is treated as a separate log record. However, some applications can actually
output logs split into multiple lines - this is often the case for stack traces, for example. If we want such a multiline log
to appear in Sumo Logic as a single record, we need to tell the collector how to distinguish between lines which start a new record
and ones which continue an existing record.

Multiline log parsing can be configured using the `sumologic.logs.multiline` section in `user-values.yaml`.

```yaml
sumologic:
  logs:
    multiline:
      enabled: true
      first_line_regex: "^\\[?\\d{4}-\\d{1,2}-\\d{1,2}.\\d{2}:\\d{2}:\\d{2}"
```

where `first_line_regex` is a regular expression used to detect the first line of a multiline log.

This feature is enabled by default. It can rarely cause problems by merging together lines which are supposed to be separate.
In that case, feel free to disable it.

### Setting source name and other built-in metadata

It's possible to customize the built-in Sumo Logic metadata (like [source name][source_name] for example) for container logs:

```yaml
sumologic:
  logs:
    container:
      ## Set the _sourceHost metadata field in Sumo Logic.
      sourceHost: "%{k8s.pod.hostname}"
      ## Set the _sourceName metadata field in Sumo Logic.
      sourceName: "%{k8s.namespace.name}.%{k8s.pod.name}.%{k8s.container.name}"
      ## Set the _sourceCategory metadata field in Sumo Logic.
      sourceCategory: "%{k8s.namespace.name}/%{k8s.pod.pod_name}"
      ## Set the prefix, for _sourceCategory metadata.
      sourceCategoryPrefix: "kubernetes/"
      ## Used to replace - with another character.
      sourceCategoryReplaceDash: "/"
```

As can be seen in the above example, these fields can contain templates of the form `%{field_name}`, where `field_name` is the name
of a resource attribute. Available resource attributes include [OpenTelemetry Kubernetes resource attributes][opentelemetry_k8s],
in addition to the following:

- `cluster`
- `_collector`
- `pod_labels_*` where * is the Pod label name

### Filtering

Logs can be excluded based on their container name, pod name, host, and namespace. This is done by providing a matching
regular expression:

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

For more advanced filtering logic, see [here](#advanced-filtering).

### Modifying log records

:construction: This needs `extraProcessors` for logs.

### Persistence

By default, the metadata enrichment service provisions and uses a Kubernetes PersistentVolume as an on-disk queue that guarantees
durability across Pod restarts and buffering in case of exporting problems.

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

Note that these settings affect persistence for metrics as well.

## Advanced Configuration

There are two ways of directly configuring OpenTelemetry Collector for both log collection and metadata enrichment.
These are both advanced features requiring a good understanding of this chart's architecture and
OpenTelemetry Collector configuration.

The `metadata.logs.config.merge` and `otellogs.config.merge` keys can be used to provide configuration that will be merged
with the Helm Chart's default configuration. It should be noted that this field is not subject to
normal backwards compatibility guarantees, the default configuration can change even in minor
versions while preserving the same end-to-end behaviour. Use of this field is discouraged - ideally
the necessary customizations should be able to be achieved without touching the otel configuration
directly. Please open an issue if your use case requires the use of this field.

The `metadata.logs.config.override` and `otellogs.config.override` keys can be used to provide configuration that will be completely
replace the default configuration. As above, care must be taken not to depend on implementation details
that may change between minor releases of this Chart.

See [Sumologic OpenTelemetry Collector configuration][configuration] for more information.

### Advanced Filtering

:construction: This needs `extraProcessors` for logs.

### Disabling container logs

Container logs are collected by default. This can be disabled by setting:

```yaml
sumologic:
  logs:
    container:
      enabled: false
```

[configuration]: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/docs/Configuration.md
[values]: /deploy/helm/sumologic/values.yaml
[source_name]: https://help.sumologic.com/docs/send-data/reference-information/metadata-naming-conventions/#Source_Name
[opentelemetry_k8s]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/resource/semantic_conventions/k8s.md
