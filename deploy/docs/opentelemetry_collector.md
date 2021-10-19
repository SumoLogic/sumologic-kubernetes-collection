# Opentelemetry Collector

Opentelemetry Collector is a software to receive, process and export logs, metrics and traces.
We offer it as drop-in replacement for Fluentd in our collection.

**This feature is currently in beta and is not recommended for production environments.**

- [Metrics](#metrics)
  - [Metrics Configuration](#metrics-configuration)
- [Logs](#logs)
  - [Logs Configuration](#logs-configuration)
- [Persistance](#persistance)
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
[`values.yaml`][values] as `otelcol.metadata.metrics.config`.

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
[`values.yaml`][values] as `otelcol.metadata.logs.config`.

If you want to modify it, please see [Sumologic Opentelemetry Collector configuration][configuration]
for more information.

[configuration]: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/docs/Configuration.md
[values]: ../helm/sumologic/values.yaml

## Persistance

The persistance can be configured in `values.yaml` by making changes under the `otelcol.persistence`:

```yaml
otelcol:
  persistence:
    enabled: true
```

and changes in Opentelemetry Collector configuration under `otelcol.metadata.metics.config` and `otelcol.metadata.logs.config`
according to [Persistent Queue][persistent-queue] documentation.

[persistent-queue]: https://github.com/open-telemetry/opentelemetry-collector/tree/main/exporter/exporterhelper#persistent-queue

When Opentelemetry Collector persistence is to be changed (enabled or disabled)
it is required to recreate or delete existing Opentelemetry Collector StatefulSets,
as it is not possible to add/remove `volumeClaimTemplate` for StatefulSet.

### Enabling persistence

  To enable persistence for Opentelemetry Collector set following configuration in `values.yaml`:

  ```yaml
  otelcol:
  persistence:
    enabled: true
  ```

  Verify that Opentelemetry Collector configuration in values.yaml contains following sections
  under `otelcol.metadata.metics.config` and `otelcol.metadata.logs.config`:

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

  and [Persistent Queue][persistent-queue] is configured for all exporters, e.g.

  ```yaml
  exporters:
    ## Configuration for Sumo Logic Exporter
    ## ref: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/pkg/exporter/sumologicexporter
    sumologic:
      ## Configuration for sending queue
      ## ref: https://github.com/open-telemetry/opentelemetry-collector/tree/main/exporter/exporterhelper#configuration
      sending_queue:
        enabled: true
        persistent_storage_enabled: '{{ .Values.otelcol.persistence.enabled }}'
  ```

  When Opentelemetry Collector persistence is to be change (persistance is disabled in existing Sumo Logic collection and
  there is a need to enable persistence) please continue with steps described below and either
  recreate Opentelemetry Collector StatefulSet or create temporary instance of Opentelemetry Collector StatefulSet and
  remove earlier created.

  **Notice**: Below steps does not need to be done when Opentelemetry Collector is deployed the first time.

- #### Enabling Opentelemetry Collector persistence by recreating StatefulSet

  In a heavy used clusters with high load of logs and metrics it might be possible that
  recreating Fluentd StatefulSet with new `volumeClaimTemplate` may cause logs and metrics
  being unavailable for the time of recreation. It usually shouldn't take more than several seconds.

  To recreate Opentelemetry Collector StatefulSets with new `volumeClaimTemplate` one can run
  the following commands for all Opentelemetry Collector StatefulSets.

  Remember to adjust `volumeClaimTemplate` (`VOLUME_CLAIM_TEMPLATE` variable in command below)
  which will be added to `volumeClaimTemplates` in StatefulSet `spec` according to your needs,
  for details please check `PersistentVolumeClaim` in Kubernetes API specification.

  Also remember to replace the `NAMESPACE` and `RELEASE_NAME` variables with proper values.

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

- #### Enabling Opentelemetry Collector persistence by creating temporary instances and removing earlier created

  TBD

### Disabling persistence

```yaml
otelcol:
  persistence:
    enabled: false
```

```yaml
  service:
    extensions:
      - health_check
      # - file_storage
```

- #### Disabling Opentelemetry Collector persistence by recreating StatefulSet

  TBD

- #### Disabling Opentelemetry Collector persistence by creating temporary instances nd removing earlier created

  TBD
