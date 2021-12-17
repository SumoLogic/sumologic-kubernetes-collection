# Opentelemetry Collector

Opentelemetry Collector is a software to receive, process and export logs, metrics and traces.
We offer it as drop-in replacement for Fluentd in our collection.

**This feature is currently in beta and is not recommended for production environments.**

- [Metrics](#metrics)
  - [Metrics Configuration](#metrics-configuration)
- [Logs](#logs)
  - [Logs Configuration](#logs-configuration)
- [Persistence](#persistence)
  - [Enabling persistence](#enabling-persistence)
  - [Disabling persistence](#disabling-persistence)

## Metrics

We are using Opentelemetry Collector like Fluentd to enrich metadata and to filter data.

To enable Opentelemetry Collector for metrics, please use the following configuration:

```yaml
sumologic:
  metrics:
    metadata:
      provider: otelcol
```

As we are providing drop-in replacement, most of the configuration from
[`values.yaml`][values] should work
the same way for Opentelemetry Collector like for Fluentd.

### Metrics Configuration

All Opentelemetry Collector configuration for metrics is located in
[`values.yaml`][values] as `metadata.metrics.config`.

If you want to modify it, please see [Sumologic Opentelemetry Collector configuration][configuration]
for more information.

## Logs

We are using Opentelemetry Collector like Fluentd to enrich metadata and to filter data.

To enable Opentelemetry Collector for logs, please use the following configuration:

```yaml
sumologic:
  logs:
    metadata:
      provider: otelcol
```

As we are providing drop-in replacement, most of the configuration from
[`values.yaml`][values] should work
the same way for Opentelemetry Collector like for Fluentd.

### Logs Configuration

All Opentelemetry Collector configuration for logs is located in
[`values.yaml`][values] as `metadata.logs.config`.

If you want to modify it, please see [Sumologic Opentelemetry Collector configuration][configuration]
for more information.

[configuration]: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/docs/Configuration.md
[values]: ../helm/sumologic/values.yaml

## Persistence

The persistence for Opentelemetry Collector can be configured in [`values.yaml`][values] by making changes under the `metadata.persistence`:

```yaml
metadata:
  persistence:
    enabled: true
```

along with changes in configuration under `metadata.metrics.config` and `metadata.logs.config`
according to [Persistent Queue][persistent_queue] documentation.

When Opentelemetry Collector persistence is to be changed (enabled or disabled)
it is required to recreate or delete existing Opentelemetry Collector StatefulSets,
as it is not possible to add/remove `volumeClaimTemplate` for StatefulSet.

[persistent_queue]: https://github.com/open-telemetry/opentelemetry-collector/tree/release/v0.37.x/exporter/exporterhelper#persistent-queue
[values]: ../helm/sumologic/values.yaml

### Enabling persistence

To enable persistence for Opentelemetry Collector set following configuration in [`values.yaml`][values]:

```yaml
metadata:
  persistence:
    enabled: true
```

Verify that Opentelemetry Collector configuration in [`values.yaml`][values] contains following sections
under `metadata.metrics.config` and `metadata.logs.config`:

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
      persistent_storage_enabled: '{{ .Values.metadata.persistence.enabled }}'
```

When Opentelemetry Collector persistence is to be changed (persistence is disabled in existing Sumo Logic collection and
there is a need to enable persistence) please continue with steps described below and either
recreate Opentelemetry Collector StatefulSet or create temporary instance of Opentelemetry Collector StatefulSet and
remove earlier created.

**_Notice:_** Below steps does not need to be done when Opentelemetry Collector is deployed the first time.

[persistent_queue]: https://github.com/open-telemetry/opentelemetry-collector/tree/release/v0.37.x/exporter/exporterhelper#persistent-queue
[values]: ../helm/sumologic/values.yaml

#### Enabling Opentelemetry Collector persistence by recreating StatefulSet

In a heavy used clusters with high load of logs and metrics it might be possible that
recreating Opentelemetry Collector StatefulSets with new `volumeClaimTemplate` may cause logs and metrics
being unavailable for the time of recreation. It usually shouldn't take more than several seconds.

To recreate Opentelemetry Collector StatefulSets with new `volumeClaimTemplate` one can run
the following commands for all Opentelemetry Collector StatefulSets.

Remember to adjust `volumeClaimTemplate` (`VOLUME_CLAIM_TEMPLATE` variable in command below)
which will be added to `volumeClaimTemplates` in StatefulSet `spec` according to your needs,
for details please check `PersistentVolumeClaim` in Kubernetes API specification.

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

**_Notice:_** When StatefulSets managed by helm are modified by commands specified above,
one might expect a warning similar to this one:

```
Warning: resource statefulsets/collection-sumologic-otelcol-metrics is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
```

Upgrade collection with  Opentelemetry Collector persistence enabled, e.g.

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
```

#### Enabling Opentelemetry Collector persistence by creating temporary instances and removing earlier created

To create a temporary instances of Opentelemetry Collector StatefulSets and avoid a loss of logs or metrics one can run the following commands.

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

Delete old instances of Opentelemetry Collector StatefulSets:

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
kubectl wait --for=condition=ready pod \
  --namespace ${NAMESPACE} \
  --selector "release==${RELEASE_NAME},heritage=tmp" && \
kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-otelcol-logs && \
kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-otelcol-metrics
```

Upgrade collection with  Opentelemetry Collector persistence enabled, e.g.

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
```

**_Notice:_** After the Helm chart upgrade is done, in order to remove temporary Opentelemetry Collector
StatefulSets run the following command:

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

To disable persistence for Opentelemetry Collector set following configuration in [`values.yaml`][values]:

```yaml
metadata:
  persistence:
    enabled: false
```

and disable [File Storage][file_storage_extension] extension in[`values.yaml`][values] under `metadata.metrics.config` and `metadata.logs.config`, e.g.

```yaml
  service:
    extensions:
      - health_check
      # - file_storage
```

When Opentelemetry Collector persistence is to be changed (persistence is enabled in existing Sumo Logic collection and
there is a need to disabled persistence) please continue with steps described below and either
recreate Opentelemetry Collector StatefulSet or create temporary instance of Opentelemetry Collector StatefulSet and
remove earlier created.

**_Notice:_** Below steps does not need to be done when Opentelemetry Collector is deployed the first time.

[file_storage_extension]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/release/v0.37.x/extension/storage/filestorage
[values]: ../helm/sumologic/values.yaml

#### Disabling Opentelemetry Collector persistence by recreating StatefulSet

In a heavy used clusters with high load of logs and metrics it might be possible that
recreating Opentelemetry Collector StatefulSets with new `volumeClaimTemplate` may cause logs and metrics
being unavailable for the time of recreation. It usually shouldn't take more than several seconds.

To recreate Opentelemetry Collector StatefulSets with new `volumeClaimTemplate` one can run
the following commands for all Opentelemetry Collector StatefulSets.

Remember to adjust `volumeClaimTemplate` (`VOLUME_CLAIM_TEMPLATE` variable in command below)
which will be added to `volumeClaimTemplates` in StatefulSet `spec` according to your needs,
for details please check `PersistentVolumeClaim` in Kubernetes API specification.

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

**_Notice:_** When StatefulSets managed by helm are modified by commands specified above,
one might expect a warning similar to this one:

```
Warning: resource statefulsets/collection-sumologic-otelcol-metrics is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
```

Upgrade collection with  Opentelemetry Collector persistence disabled, e.g.

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
```

#### Disabling Opentelemetry Collector persistence by creating temporary instances nd removing earlier created

To create a temporary instances of Opentelemetry Collector StatefulSets and avoid a loss of logs or metrics one can run the following commands.

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

Delete old instances of Opentelemetry Collector StatefulSets:

```bash
NAMESPACE=sumologic && \
RELEASE_NAME=collection && \
kubectl wait --for=condition=ready pod \
  --namespace ${NAMESPACE} \
  --selector "release==${RELEASE_NAME},heritage=tmp" && \
kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-otelcol-logs && \
kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-otelcol-metrics
```

Upgrade collection with  Opentelemetry Collector persistence disabled, e.g.

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
```

**_Notice:_** After the Helm chart upgrade is done, it is needed to remove temporary Opentelemetry Collector StatefulSets
and remaining `PersistentVolumeClaims` which are no longer used by Opentelemetry Collector StatefulSets.

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
