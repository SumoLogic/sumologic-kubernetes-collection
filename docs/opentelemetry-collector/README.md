# OpenTelemetry Collector

OpenTelemetry Collector is a software to receive, process and export logs, metrics and traces. We offer it as drop-in replacement for
Fluentd in our collection.

- [Metrics](metrics.md)
  - [Metrics metdata](metrics.md#metrics-metadata)
  - [Metrics collector](metrics.md#metrics-collector)
- [Logs](logs.md)
  - [Logs Configuration](logs.md#logs-configuration)
  - [Multiline Log Parsing](logs.md#multiline-log-parsing)
  - [Container Logs](logs.md#container-logs)
  - [SystemD Logs](logs.md#systemd-logs)
  - [Running otelcol and Fluent Bit side by side](logs.md#running-otelcol-and-fluent-bit-side-by-side)
- [Persistence](#persistence)
  - [Enabling persistence](#enabling-persistence)
    - [Enabling OpenTelemetry Collector persistence by recreating StatefulSet](#enabling-opentelemetry-collector-persistence-by-recreating-statefulset)
    - [Enabling OpenTelemetry Collector persistence by creating temporary instances and removing earlier created](#enabling-opentelemetry-collector-persistence-by-creating-temporary-instances-and-removing-earlier-created)
  - [Disabling persistence](#disabling-persistence)
    - [Disabling OpenTelemetry Collector persistence by recreating StatefulSet](#disabling-opentelemetry-collector-persistence-by-recreating-statefulset)
    - [Disabling OpenTelemetry Collector persistence by creating temporary instances nd removing earlier created](#disabling-opentelemetry-collector-persistence-by-creating-temporary-instances-nd-removing-earlier-created)
- [Traces](traces.md)
  - [Load balancing using the gateway](traces.md#load-balancing-using-the-gateway)
- [Kubernetes Events](events.md)
  - [Customizing OpenTelemetry Collector configuration](events.md#customizing-opentelemetry-collector-configuration)

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
[values]: /deploy/helm/sumologic/values.yaml
