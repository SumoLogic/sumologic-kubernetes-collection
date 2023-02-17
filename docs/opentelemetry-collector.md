# OpenTelemetry Collector

OpenTelemetry Collector is a software to receive, process and export logs, metrics and traces. We offer it as drop-in replacement for
Fluentd in our collection.

- [Metrics](#metrics)
  - [Metrics Configuration](#metrics-configuration)
- [Logs](#logs)
  - [Logs Configuration](#logs-configuration)
  - [Multiline Log Parsing](#multiline-log-parsing)
  - [Container Logs](#container-logs)
  - [SystemD Logs](#systemd-logs)
- [Persistence](#persistence)
  - [Enabling persistence](#enabling-persistence)
    - [Enabling OpenTelemetry Collector persistence by recreating StatefulSet](#enabling-opentelemetry-collector-persistence-by-recreating-statefulset)
    - [Enabling OpenTelemetry Collector persistence by creating temporary instances and removing earlier created](#enabling-opentelemetry-collector-persistence-by-creating-temporary-instances-and-removing-earlier-created)
  - [Disabling persistence](#disabling-persistence)
    - [Disabling OpenTelemetry Collector persistence by recreating StatefulSet](#disabling-opentelemetry-collector-persistence-by-recreating-statefulset)
    - [Disabling OpenTelemetry Collector persistence by creating temporary instances nd removing earlier created](#disabling-opentelemetry-collector-persistence-by-creating-temporary-instances-nd-removing-earlier-created)
- [Traces](#traces)
  - [Load balancing using the gateway](#load-balancing-using-the-gateway)
- [Kubernetes Events](#kubernetes-events)
  - [Customizing OpenTelemetry Collector configuration](#customizing-opentelemetry-collector-configuration)

## Metrics

We are using OpenTelemetry Collector like Fluentd to enrich metadata and to filter data.

To enable OpenTelemetry Collector for metrics, please use the following configuration:

```yaml
sumologic:
  metrics:
    metadata:
      provider: otelcol
```

As we are providing drop-in replacement, most of the configuration from [`values.yaml`][values] should work the same way for OpenTelemetry
Collector like for Fluentd.

### Metrics Configuration

There are two ways of directly configuring OpenTelemetry Collector for metrics metadata. These are both advanced features requiring a good
understanding of this chart's architecture and OpenTelemetry Collector configuration

The `metadata.metrics.config.merge` key can be used to provide configuration that will be merged with the Helm Chart's default
configuration. It should be noted that this field is not subject to normal backwards compatibility guarantees, the default configuration can
change even in minor versions while preserving the same end-to-end behaviour. Use of this field is discouraged - ideally the necessary
customizations should be able to be achieved without touching the otel configuration directly. Please open an issue if your use case
requires the use of this field.

The `metadata.metrics.config.override` key can be used to provide configuration that will be completely replace the default configuration.
As above, care must be taken not to depend on implementation details that may change between minor releases of this Chart.

If you want to modify it, please see [Sumologic OpenTelemetry Collector configuration][configuration] for more information.

## Logs

OpenTelemetry Collector can be used for both log collection and metadata enrichment. For these roles, it replaces respectively Fluent Bit
and Fluentd.

For log collection, it can be enabled by setting:

```yaml
sumologic:
  logs:
    collector:
      otelcol:
        enabled: true

fluent-bit:
  enabled: false
```

> **NOTE** Normally, Fluent Bit must be disabled for OpenTelemetry Collector to be enabled. This restriction can be lifted, see
> [here](#running-otelcol-and-fluent-bit-side-by-side).

For metadata enrichment, it can be enabled by setting:

```yaml
sumologic:
  logs:
    metadata:
      provider: otelcol
```

If you haven't modified the Fluentd or Fluent Bit configuration, this should be a drop-in replacement with no further changes required.

### Logs Configuration

High level OpenTelemetry Collector configuration for logs is located in [`values.yaml`][values] under the `sumologic.logs` key.

Configuration specific to the log collector DaemonSet can be found under the `otellogs` key.

Finally, configuration specific to the metadata enrichment StatefulSet can be found under the `metadata.logs` key.

There are two ways of directly configuring OpenTelemetry Collector in either of these cases. These are both advanced features requiring a
good understanding of this chart's architecture and OpenTelemetry Collector configuration.

The `metadata.logs.config.merge` and `otellogs.config.merge` keys can be used to provide configuration that will be merged with the Helm
Chart's default configuration. It should be noted that this field is not subject to normal backwards compatibility guarantees, the default
configuration can change even in minor versions while preserving the same end-to-end behaviour. Use of this field is discouraged - ideally
the necessary customizations should be able to be achieved without touching the otel configuration directly. Please open an issue if your
use case requires the use of this field.

The `metadata.logs.config.override` and `otellogs.config.override` keys can be used to provide configuration that will be completely replace
the default configuration. As above, care must be taken not to depend on implementation details that may change between minor releases of
this Chart.

[configuration]: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/docs/configuration.md
[values]: /deploy/helm/sumologic/values.yaml

### Multiline log parsing

Multiline log parsing for OpenTelemetry Collector can be configured using the `sumologic.logs.multiline` section in `user-values.yaml`.

```yaml
sumologic:
  logs:
    multiline:
      enabled: true
      first_line_regex: "^\\[?\\d{4}-\\d{1,2}-\\d{1,2}.\\d{2}:\\d{2}:\\d{2}"
```

where `first_line_regex` is a regular expression used to detect the first line of a multiline log.

### Container Logs

Container logs are collected by default. This can be disabled by setting:

```yaml
sumologic:
  logs:
    container:
      enabled: false
```

### SystemD Logs

Systemd logs are collected by default. This can be disabled by setting:

```yaml
sumologic:
  logs:
    systemd:
      enabled: false
```

It's also possible to change which SystemD units we want to collect logs from. For example, the below configuration only gets logs from the
Docker service:

```yaml
sumologic:
  logs:
    systemd:
      units:
        - docker.service
```

### Running otelcol and Fluent Bit side by side

Normally, enabling both Otelcol and Fluent-Bit for log collection will fail with an error. The reason for this is that doing so naively
results in each log line being delivered twice to Sumo Logic, incurring twice the cost without any benefit. However, there are reasons to do
this; for example it makes for a smoother and less risky migration. Advanced users may also want to pin the different collectors to
different Node groups.

Because of this, we've included a way to allow running otelcol and Fluent Bit side by side. The minimal configuration enabling this is:

```yaml
sumologic:
  logs:
    collector:
      otelcol:
        enabled: true
      allowSideBySide: true

fluent-bit:
  enabled: true
```

> **WARNING** Without further modifications to Otelcol and Fluent Bit configuration, this will cause each log line to be ingested twice,
> potentially doubling the cost of logs ingestion.

## Persistence

The persistence for OpenTelemetry Collector can be configured in `user-values.yaml` by making changes under the `metadata.persistence`:

```yaml
metadata:
  persistence:
    enabled: true
```

along with changes in configuration under `metadata.metrics.config` and `metadata.logs.config` according to [Persistent
Queue][persistent_queue] documentation.

When OpenTelemetry Collector persistence is to be changed (enabled or disabled) it is required to recreate or delete existing OpenTelemetry
Collector StatefulSets, as it is not possible to add/remove `volumeClaimTemplate` for StatefulSet.

[persistent_queue]: https://github.com/open-telemetry/opentelemetry-collector/tree/release/v0.37.x/exporter/exporterhelper#persistent-queue

### Enabling persistence

To enable persistence for OpenTelemetry Collector set following configuration in `user-values.yaml`:

```yaml
metadata:
  persistence:
    enabled: true
```

Verify that OpenTelemetry Collector configuration in [`values.yaml`][values] contains following sections under `metadata.metrics.config` and
`metadata.logs.config`:

```yaml
extensions:
  file_storage:
  directory: /var/lib/storage/otc
  timeout: 10s
```

```yaml
service:
  extensions:
    - file_storage
```

and [Persistent Queue][persistent_queue] is configured for all exporters, e.g.

```yaml
exporters:
  ## Configuration for Sumo Logic Exporter
  ## ref: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/pkg/exporter/sumologicexporter
  sumologic:
    ## Configuration for sending queue
    ## ref: https://github.com/open-telemetry/opentelemetry-collector/tree/release/v0.37.x/exporter/exporterhelper#configuration
    sending_queue:
      enabled: true
      persistent_storage_enabled: "{{ .Values.metadata.persistence.enabled }}"
```

When OpenTelemetry Collector persistence is to be changed (persistence is disabled in existing Sumo Logic collection and there is a need to
enable persistence) please continue with steps described below and either recreate OpenTelemetry Collector StatefulSet or create temporary
instance of OpenTelemetry Collector StatefulSet and remove earlier created.

**_Notice:_** Below steps does not need to be done when OpenTelemetry Collector is deployed the first time.

#### Enabling OpenTelemetry Collector persistence by recreating StatefulSet

In a heavy used clusters with high load of logs and metrics it might be possible that recreating OpenTelemetry Collector StatefulSets with
new `volumeClaimTemplate` may cause logs and metrics being unavailable for the time of recreation. It usually shouldn't take more than
several seconds.

To recreate OpenTelemetry Collector StatefulSets with new `volumeClaimTemplate` one can run the following commands for all OpenTelemetry
Collector StatefulSets.

Remember to adjust `volumeClaimTemplate` (`VOLUME_CLAIM_TEMPLATE` variable in command below) which will be added to `volumeClaimTemplates`
in StatefulSet `spec` according to your needs, for details please check `PersistentVolumeClaim` in Kubernetes API specification.

Also remember to replace the `NAMESPACE` and `RELEASE_NAME` variables with proper values.

**_Notice:_** Before executing below steps, please make sure that you have [`yq`][yq] in version: `3.4.0` <= `x` < `4.0.0`.

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
STATEFULSET_NAME=${RELEASE_NAME}-sumologic-otelcol-logs && \
VOLUME_CLAIM_TEMPLATE=$(cat <<-"EOF"
metadata:
  name: file-storage
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF
) && \
FILE_STORAGE_VOLUME=$(cat <<-"EOF"
mountPath: /var/lib/storage/otc
name: file-storage
EOF
)&& \
kubectl --namespace ${NAMESPACE} get statefulset ${STATEFULSET_NAME} --output yaml | \
yq w - "spec.volumeClaimTemplates[+]" --from <(echo "${VOLUME_CLAIM_TEMPLATE}") | \
yq w - "spec.template.spec.containers[0].volumeMounts[+]" --from <(echo "${FILE_STORAGE_VOLUME}") | \
kubectl apply --namespace ${NAMESPACE} --force --filename -
```

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
STATEFULSET_NAME=${RELEASE_NAME}-sumologic-otelcol-metrics && \
VOLUME_CLAIM_TEMPLATE=$(cat <<-"EOF"
metadata:
  name: file-storage
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF
) && \
FILE_STORAGE_VOLUME=$(cat <<-"EOF"
mountPath: /var/lib/storage/otc
name: file-storage
EOF
)&& \
kubectl --namespace ${NAMESPACE} get statefulset ${STATEFULSET_NAME} --output yaml | \
yq w - "spec.volumeClaimTemplates[+]" --from <(echo "${VOLUME_CLAIM_TEMPLATE}") | \
yq w - "spec.template.spec.containers[0].volumeMounts[+]" --from <(echo "${FILE_STORAGE_VOLUME}") | \
kubectl apply --namespace ${NAMESPACE} --force --filename -
```

**_Notice:_** When StatefulSets managed by helm are modified by commands specified above, one might expect a warning similar to this one:

```
Warning: resource statefulsets/collection-sumologic-otelcol-metrics is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
```

Upgrade collection with OpenTelemetry Collector persistence enabled, e.g.

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
```

#### Enabling OpenTelemetry Collector persistence by creating temporary instances and removing earlier created

To create a temporary instances of OpenTelemetry Collector StatefulSets and avoid a loss of logs or metrics one can run the following
commands.

Remember to replace the `NAMESPACE` and `RELEASE_NAME`, variables with proper values.

**_Notice:_** Before executing below steps, please make sure that you have [`yq`][yq] in version: `3.4.0` <= `x` < `4.0.0`.

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
STATEFULSET_NAME=${RELEASE_NAME}-sumologic-otelcol-logs && \
kubectl get statefulset --namespace ${NAMESPACE} ${STATEFULSET_NAME} --output yaml | \
yq w - "metadata.name" tmp-${STATEFULSET_NAME} | \
yq w - "metadata.labels[heritage]" "tmp" | \
yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
kubectl create --filename -
```

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
STATEFULSET_NAME=${RELEASE_NAME}-sumologic-otelcol-metrics && \
kubectl get statefulset --namespace ${NAMESPACE} ${STATEFULSET_NAME} --output yaml | \
yq w - "metadata.name" tmp-${STATEFULSET_NAME} | \
yq w - "metadata.labels[heritage]" "tmp" | \
yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
kubectl create --filename -
```

Delete old instances of OpenTelemetry Collector StatefulSets:

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
kubectl wait --for=condition=ready pod \
  --namespace ${NAMESPACE} \
  --selector "release==${RELEASE_NAME},heritage=tmp" && \
kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-otelcol-logs && \
kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-otelcol-metrics
```

Upgrade collection with OpenTelemetry Collector persistence enabled, e.g.

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
```

**_Notice:_** After the Helm chart upgrade is done, in order to remove temporary OpenTelemetry Collector StatefulSets run the following
command:

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
kubectl wait --for=condition=ready pod \
  --namespace ${NAMESPACE} \
  --selector "release==${RELEASE_NAME},heritage=Helm" && \
kubectl delete statefulset \
  --namespace ${NAMESPACE} \
  --selector "release==${RELEASE_NAME},heritage=tmp"
```

### Disabling persistence

To disable persistence for OpenTelemetry Collector set following configuration in `user-values.yaml`:

```yaml
metadata:
  persistence:
    enabled: false
```

and disable [File Storage][file_storage_extension] extension in[`values.yaml`][values] under `metadata.metrics.config` and
`metadata.logs.config`, e.g.

```yaml
service:
  extensions:
    - health_check
    # - file_storage
```

When OpenTelemetry Collector persistence is to be changed (persistence is enabled in existing Sumo Logic collection and there is a need to
disabled persistence) please continue with steps described below and either recreate OpenTelemetry Collector StatefulSet or create temporary
instance of OpenTelemetry Collector StatefulSet and remove earlier created.

**_Notice:_** Below steps does not need to be done when OpenTelemetry Collector is deployed the first time.

[file_storage_extension]:
  https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/release/v0.37.x/extension/storage/filestorage

#### Disabling OpenTelemetry Collector persistence by recreating StatefulSet

In a heavy used clusters with high load of logs and metrics it might be possible that recreating OpenTelemetry Collector StatefulSets with
new `volumeClaimTemplate` may cause logs and metrics being unavailable for the time of recreation. It usually shouldn't take more than
several seconds.

To recreate OpenTelemetry Collector StatefulSets with new `volumeClaimTemplate` one can run the following commands for all OpenTelemetry
Collector StatefulSets.

Remember to adjust `volumeClaimTemplate` (`VOLUME_CLAIM_TEMPLATE` variable in command below) which will be added to `volumeClaimTemplates`
in StatefulSet `spec` according to your needs, for details please check `PersistentVolumeClaim` in Kubernetes API specification.

Also remember to replace the `NAMESPACE` and `RELEASE_NAME` variables with proper values.

**_Notice:_** Before executing below steps, please make sure that you have [`yq`][yq] in version: `3.4.0` <= `x` < `4.0.0`.

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
STATEFULSET_NAME=${RELEASE_NAME}-sumologic-otelcol-logs && \
kubectl --namespace ${NAMESPACE} get statefulset ${STATEFULSET_NAME} --output yaml | \
yq d - "spec.template.spec.containers[*].volumeMounts(name==file-storage)" | \
yq d - "spec.volumeClaimTemplates(metadata.name==file-storage)" | \
kubectl apply --namespace ${NAMESPACE} --force --filename -
```

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
STATEFULSET_NAME=${RELEASE_NAME}-sumologic-otelcol-metrics && \
kubectl --namespace ${NAMESPACE} get statefulset ${STATEFULSET_NAME} --output yaml | \
yq d - "spec.template.spec.containers[*].volumeMounts(name==file-storage)" | \
yq d - "spec.volumeClaimTemplates(metadata.name==file-storage)" | \
kubectl apply --namespace ${NAMESPACE} --force --filename -
```

**_Notice:_** When StatefulSets managed by helm are modified by commands specified above, one might expect a warning similar to this one:

```
Warning: resource statefulsets/collection-sumologic-otelcol-metrics is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
```

Upgrade collection with OpenTelemetry Collector persistence disabled, e.g.

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
```

#### Disabling OpenTelemetry Collector persistence by creating temporary instances nd removing earlier created

To create a temporary instances of OpenTelemetry Collector StatefulSets and avoid a loss of logs or metrics one can run the following
commands.

Remember to replace the `NAMESPACE` and `RELEASE_NAME` variables with proper values.

**_Notice:_** Before executing below steps, please make sure that you have [`yq`][yq] in version: `3.4.0` <= `x` < `4.0.0`.

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
STATEFULSET_NAME=${RELEASE_NAME}-sumologic-otelcol-logs && \
kubectl get statefulset --namespace ${NAMESPACE} ${STATEFULSET_NAME} --output yaml | \
yq w - "metadata.name" tmp-${STATEFULSET_NAME} | \
yq w - "metadata.labels[heritage]" "tmp" | \
yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
kubectl create --filename -
```

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
STATEFULSET_NAME=${RELEASE_NAME}-sumologic-otelcol-metrics && \
kubectl get statefulset --namespace ${NAMESPACE} ${STATEFULSET_NAME} --output yaml | \
yq w - "metadata.name" tmp-${STATEFULSET_NAME} | \
yq w - "metadata.labels[heritage]" "tmp" | \
yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
kubectl create --filename -
```

Delete old instances of OpenTelemetry Collector StatefulSets:

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
kubectl wait --for=condition=ready pod \
  --namespace ${NAMESPACE} \
  --selector "release==${RELEASE_NAME},heritage=tmp" && \
kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-otelcol-logs && \
kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-otelcol-metrics
```

Upgrade collection with OpenTelemetry Collector persistence disabled, e.g.

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
```

**_Notice:_** After the Helm chart upgrade is done, it is needed to remove temporary OpenTelemetry Collector StatefulSets and remaining
`PersistentVolumeClaims` which are no longer used by OpenTelemetry Collector StatefulSets.

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
kubectl wait --for=condition=ready pod \
  --namespace ${NAMESPACE} \
  --selector "release==${RELEASE_NAME},heritage=Helm" && \
kubectl delete statefulset \
  --namespace ${NAMESPACE} \
  --selector "release==${RELEASE_NAME},heritage=tmp"
```

To remove remaining `PersistentVolumeClaims`:

```bash
kubectl delete pvc --namespace ${NAMESPACE} --selector app=${RELEASE_NAME}-sumologic-otelcol-logs
kubectl delete pvc --namespace ${NAMESPACE} --selector app=${RELEASE_NAME}-sumologic-otelcol-metrics
```

[yq]: https://mikefarah.gitbook.io/yq/v/v3.x/

## Traces

### Load balancing using the gateway

Open Telemetry supports Trace ID aware load balancing. An example use case for load balancing is scaling `cascading_filter` that requires
spans with same Trace ID to be send to the same collector instance.

Sumo Logic kubernetes collection supports three layer architecture - with an agent, gateway and a collector - in order to perform Trace ID
aware load balancing.

Agent, if the gateway is enabled, sends traces to the gateway. Gateway is configured with a load balancing exporter pointing to the
collector headless service. Gateway may also be exposed outside cluster, allowing to load balance traces originating from outside kubernetes
cluster.

Sample config:

```yaml
sumologic:
  traces:
    enabled: true

  otelagent:
    enabled: true

  otelgateway:
    enabled: true
```

Refs:

- [Trace ID aware load balancing](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/loadbalancingexporter/README.md)
- [Using cascading_filter](https://help.sumologic.com/docs/apm/traces/advanced-configuration/filter-shape-tracing-data)

## Kubernetes Events

OpenTelemetry Collector can be used to collect and enrich Kubernetes events instead of Fluentd. This is a drop-in replacement. To do this,
set the `sumologic.events.provider` to `otelcol`:

```yaml
sumologic:
  events:
    provider: otelcol
```

For configurations that don't modify `sumologic.fluentd.events.overrideOutputConf`, this should be enough. See the configuration options
under `otelevents` in [values.yaml](/deploy/helm/sumologic/values.yaml) for OT-specific configuration..

### Customizing OpenTelemetry Collector configuration

If the configuration options present under the `otelevents` key aren't sufficient for your needs, you can override the OT configuration
directly.

The `otelevents.config.merge` key can be used to provide configuration that will be merged with the Helm Chart's default configuration. It
should be noted that this field is not subject to normal backwards compatibility guarantees, the default configuration can change even in
minor versions while preserving the same end-to-end behaviour. Use of this field is discouraged - ideally the necessary customizations
should be able to be achieved without touching the otel configuration directly. Please open an issue if your use case requires the use of
this field.

The `otelevents.config.override` key can be used to provide configuration that will be completely replace the default configuration. As
above, care must be taken not to depend on implementation details that may change between minor releases of this Chart.
