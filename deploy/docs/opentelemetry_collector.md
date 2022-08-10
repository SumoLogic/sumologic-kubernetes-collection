# Opentelemetry Collector

Opentelemetry Collector is a software to receive, process and export logs, metrics and traces.
We offer it as drop-in replacement for Fluentd in our collection.

> :warning: **This feature is currently in beta and its configuration can change. It is nonetheless production-ready and will become the default in the next major version.**

- [Metrics](#metrics)
  - [Metrics Configuration](#metrics-configuration)
- [Logs Metadata](#logs-metadata)
  - [Logs Configuration](#logs-configuration)
- [Scraping Containers Logs](#scraping-containers-logs)
- [Persistence](#persistence)
  - [Enabling persistence](#enabling-persistence)
    - [Enabling Opentelemetry Collector persistence by recreating StatefulSet](#enabling-opentelemetry-collector-persistence-by-recreating-statefulset)
    - [Enabling Opentelemetry Collector persistence by creating temporary instances and removing earlier created](#enabling-opentelemetry-collector-persistence-by-creating-temporary-instances-and-removing-earlier-created)
  - [Disabling persistence](#disabling-persistence)
    - [Disabling Opentelemetry Collector persistence by recreating StatefulSet](#disabling-opentelemetry-collector-persistence-by-recreating-statefulset)
    - [Disabling Opentelemetry Collector persistence by creating temporary instances nd removing earlier created](#disabling-opentelemetry-collector-persistence-by-creating-temporary-instances-nd-removing-earlier-created)
- [Traces](#traces)
  - [Load balancing using the gateway](#load-balancing-using-the-gateway)
- [Kubernetes Events](#kubernetes-events)
  - [Customizing OpenTelemetry Collector configuration](#customizing-opentelemetry-collector-configuration)

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

## Logs Metadata

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

## Scraping Containers Logs

We are using Opentelemetry Collector like Fluent Bit to scrape container logs.

**Note:** Opentelemetry Collector does not support systemd logs yet.

In order to use Opentelemetry Collector to scrape container logs, please use the following configuration:

```yaml
## Opentelemetry as log collector is not compatible with Fluentd
sumologic:
  logs:
    metadata:
      provider: otelcol

## Enable processing logs from Opentelemetry as log collector
metadata:
  logs:
    config:
      service:
        pipelines:
          logs/otlp/containers:
            receivers:
              - otlp
            processors:
              - memory_limiter
              - groupbyattrs/containers
              - k8s_tagger
              - source/containers
              - resource/containers_copy_node_to_host
              - batch
            exporters:
              - sumologic/containers

## Enable Opentelemetry as log collector
otellogs:
  enabled: true

## Stop collecting container logs by fluent-bit configuration
fluent-bit:
  config:
    inputs: |
      # [INPUT]
      #     Name                tail
      #     Path                /var/log/containers/*.log
      #     Docker_Mode         On
      #     Docker_Mode_Parser  multi_line
      #     Tag                 containers.*
      #     Refresh_Interval    1
      #     Rotate_Wait         60
      #     Mem_Buf_Limit       5MB
      #     Skip_Long_Lines     On
      #     DB                  /tail-db/tail-containers-state-sumo.db
      #     DB.Sync             Normal
      [INPUT]
          Name            systemd
          Tag             host.*
          DB              /tail-db/systemd-state-sumo.db
          Systemd_Filter  _SYSTEMD_UNIT=addon-config.service
          Systemd_Filter  _SYSTEMD_UNIT=addon-run.service
          Systemd_Filter  _SYSTEMD_UNIT=cfn-etcd-environment.service
          Systemd_Filter  _SYSTEMD_UNIT=cfn-signal.service
          Systemd_Filter  _SYSTEMD_UNIT=clean-ca-certificates.service
          Systemd_Filter  _SYSTEMD_UNIT=containerd.service
          Systemd_Filter  _SYSTEMD_UNIT=coreos-metadata.service
          Systemd_Filter  _SYSTEMD_UNIT=coreos-setup-environment.service
          Systemd_Filter  _SYSTEMD_UNIT=coreos-tmpfiles.service
          Systemd_Filter  _SYSTEMD_UNIT=dbus.service
          Systemd_Filter  _SYSTEMD_UNIT=docker.service
          Systemd_Filter  _SYSTEMD_UNIT=efs.service
          Systemd_Filter  _SYSTEMD_UNIT=etcd-member.service
          Systemd_Filter  _SYSTEMD_UNIT=etcd.service
          Systemd_Filter  _SYSTEMD_UNIT=etcd2.service
          Systemd_Filter  _SYSTEMD_UNIT=etcd3.service
          Systemd_Filter  _SYSTEMD_UNIT=etcdadm-check.service
          Systemd_Filter  _SYSTEMD_UNIT=etcdadm-reconfigure.service
          Systemd_Filter  _SYSTEMD_UNIT=etcdadm-save.service
          Systemd_Filter  _SYSTEMD_UNIT=etcdadm-update-status.service
          Systemd_Filter  _SYSTEMD_UNIT=flanneld.service
          Systemd_Filter  _SYSTEMD_UNIT=format-etcd2-volume.service
          Systemd_Filter  _SYSTEMD_UNIT=kube-node-taint-and-uncordon.service
          Systemd_Filter  _SYSTEMD_UNIT=kubelet.service
          Systemd_Filter  _SYSTEMD_UNIT=ldconfig.service
          Systemd_Filter  _SYSTEMD_UNIT=locksmithd.service
          Systemd_Filter  _SYSTEMD_UNIT=logrotate.service
          Systemd_Filter  _SYSTEMD_UNIT=lvm2-monitor.service
          Systemd_Filter  _SYSTEMD_UNIT=mdmon.service
          Systemd_Filter  _SYSTEMD_UNIT=nfs-idmapd.service
          Systemd_Filter  _SYSTEMD_UNIT=nfs-mountd.service
          Systemd_Filter  _SYSTEMD_UNIT=nfs-server.service
          Systemd_Filter  _SYSTEMD_UNIT=nfs-utils.service
          Systemd_Filter  _SYSTEMD_UNIT=node-problem-detector.service
          Systemd_Filter  _SYSTEMD_UNIT=ntp.service
          Systemd_Filter  _SYSTEMD_UNIT=oem-cloudinit.service
          Systemd_Filter  _SYSTEMD_UNIT=rkt-gc.service
          Systemd_Filter  _SYSTEMD_UNIT=rkt-metadata.service
          Systemd_Filter  _SYSTEMD_UNIT=rpc-idmapd.service
          Systemd_Filter  _SYSTEMD_UNIT=rpc-mountd.service
          Systemd_Filter  _SYSTEMD_UNIT=rpc-statd.service
          Systemd_Filter  _SYSTEMD_UNIT=rpcbind.service
          Systemd_Filter  _SYSTEMD_UNIT=set-aws-environment.service
          Systemd_Filter  _SYSTEMD_UNIT=system-cloudinit.service
          Systemd_Filter  _SYSTEMD_UNIT=systemd-timesyncd.service
          Systemd_Filter  _SYSTEMD_UNIT=update-ca-certificates.service
          Systemd_Filter  _SYSTEMD_UNIT=user-cloudinit.service
          Systemd_Filter  _SYSTEMD_UNIT=var-lib-etcd2.service
          Max_Entries     1000
          Read_From_Tail  true
```

**WARNING:** Applying above configuration is related to increased ingest for rolling out time:

- Fluent Bit is still pushing containers logs until it completes rolling out
- Opentelemetry is pushing non-rotated logs during first run (this causes duplication of old logs)

In order to mitigate that, we recommend to manually increase number of [Opentelemetry Collector metadata pods](#logs-metadata)
(at least double) for update time. Please consider the following snippet:

```yaml
metadata:
  logs:
    # for autoscaling
    autoscaling:
      minReplicas: x  # x should be double of your actual number of pods
    # without autoscaling
    statefulset:
      replicaCount: x  # x should be double of your actual number of pods
```

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

## Traces

### Load balancing using the gateway

Open Telemetry supports Trace ID aware load balancing. An example use case for load balancing is scaling `cascading_filter` that requires spans with same Trace ID to be send to the same collector instance.

Sumo Logic kubernetes collection supports three layer architecture - with an agent, gateway and a collector - in order to perform Trace ID aware load balancing.

Agent, if the gateway is enabled, sends traces to the gateway. Gateway is configured with a load balancing exporter pointing to the collector headless service. Gateway may also be exposed outside cluster, allowing to load balance traces originating from outside kubernetes cluster.

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
- [Using cascading_filter](https://help.sumologic.com/Traces/03Advanced_Configuration/What_if_I_don't_want_to_send_all_the_tracing_data_to_Sumo_Logic%3F)

## Kubernetes Events

OpenTelemetry Collector can be used to collect and enrich Kubernetes events instead of Fluentd.
This is a drop-in replacement. To do this, set the `sumologic.events.provider` to `otelcol`:

```yaml
sumologic:
  events:
    provider: otelcol
```

Currently the OT configuration directly uses the following Fluentd configuration values:

- `fluentd.events.sourceCategory` to specify the [source category][source_category] for the event logs
- `fluentd.events.sourceName` to specify the [source name][source_name] for the event logs

For configurations that don't modify `sumologic.fluentd.events.overrideOutputConf`, this should be enough. See the configuration
options under `otelevents` in [values.yaml](../helm/sumologic/values.yaml).

[source_category]: https://help.sumologic.com/03Send-Data/Sources/04Reference-Information-for-Sources/Metadata-Naming-Conventions#Source_Categories
[source_name]: https://help.sumologic.com/03Send-Data/Sources/04Reference-Information-for-Sources/Metadata-Naming-Conventions#Source_Name

### Customizing OpenTelemetry Collector configuration

If the configuration options present under the `otelevents` key aren't sufficient for your needs, you can override
the OT configuration directly. Be aware that doing this isn't subject to normal backwards-compatibility guarantees offered by
this chart, so you'll need to be more careful during upgrades. The exact OT configuration emitted by the chart may change
even in minor releases.

In order to override the configuration, use the `otelevents.config.override` key. This key takes a yaml object, whose
value is merged with the configuration generated by the Chart.
