# Kubernetes Collection `v3.0.0` - Breaking Changes

<!-- TOC -->

- [Important changes](#important-changes)
  - [OpenTelemetry Collector](#opentelemetry-collector)
  - [kube-prometheus-stack upgrade](#kube-prometheus-stack-upgrade)
  - [Tracing enabled by default](#tracing-enabled-by-default)
- [How to upgrade](#how-to-upgrade)
  - [Requirements](#requirements)
  - [Migrating the configuration](#migrating-the-configuration)
  - [Metrics migration](#metrics-migration)
    - [Upgrade kube-prometheus-stack](#upgrade-kube-prometheus-stack)
    - [Otelcol StatefulSet](#otelcol-statefulset)
    - [Additional Service Monitors](#additional-service-monitors)
    - [Remote Write Migration](#remote-write-migration)
    - [Custom metrics filtering and modification](#custom-metrics-filtering-and-modification)
  - [Logs migration](#logs-migration)
    - [Replacing Fluent Bit with OpenTelemetry Collector](#replacing-fluent-bit-with-opentelemetry-collector)
      - [Migration with (small) data loss](#migration-with-small-data-loss)
      - [Migration with data duplication](#migration-with-data-duplication)
      - [Migration without data duplication and data loss (advanced)](#migration-without-data-duplication-and-data-loss-advanced)
    - [Otelcol StatefulSet](#otelcol-statefulset)
    - [Custom logs filtering and processing](#custom-logs-filtering-and-processing)
  - [Tracing migration](#tracing-migration)
    - [Replace special configuration values marked by 'replace' suffix](#replace-special-configuration-values-marked-by-replace-suffix)
    - [OpenTelemetry Collector Deployments](#opentelemetry-collector-deployments)
  - [Running the helm upgrade](#running-the-helm-upgrade)
  - [Known issues](#known-issues)
    - [Cannot delete pod if using Tailing Sidecar Operator](#cannot-delete-pod-if-using-tailing-sidecar-operator)
    - [OpenTelemetry Collector doesn't read logs from the beginning of files](#opentelemetry-collector-doesnt-read-logs-from-the-beginning-of-files)
- [Full list of changes](#full-list-of-changes)
<!-- /TOC -->

Based on feedback from our users, we will be introducing several changes to the Sumo Logic Kubernetes Collection solution.

This document describes the major changes and the necessary migration steps.

## Important changes

### OpenTelemetry Collector

The new version replaces both Fluentd and Fluent Bit with the OpenTelemetry Collector. In the majority of cases, this doesn't require any
manual intervention. However, custom processing in Fluentd or Fluent Bit will need to be ported to the OpenTelemetry Collector configuration
format. See below for details.

### kube-prometheus-stack upgrade

We've upgraded kube-prometheus-stack, which results in some changes to metrics, and a need for some manual intervention during the upgrade.

### Tracing enabled by default

Trace collection is now enabled by default. If you don't have instrumented applications in your cluster, or don't want to collect traces,
you'll need to disable this feature manually.

## How to upgrade

### Requirements

- `helm3`
- `kubectl`
- `jq`
- `docker`

Set the following environment variables that our commands will make use of:

```bash
export NAMESPACE=...
export HELM_RELEASE_NAME=...
```

### Migrating the configuration

We've made some breaking changes to our configuration file format, but most of them will be handled automatically by our migration tool.

You can get your current configuration from the cluster by running:

```bash
helm get values --namespace "${NAMESPACE}" --output yaml "${HELM_RELEASE_NAME}" > user-values.yaml
```

Afterwards, you can download the migration tool and run it directly. Set the OS and ARCH variables to your operating system and
architecture.

```bash
OS=linux ARCH=amd64; curl -L "https://github.com/SumoLogic/sumologic-kubernetes-tools/releases/download/v2.19.0/update-collection-v3-sumo-${OS}_${ARCH}" -o update-collection-v3
chmod +x update-collection-v3
./update-collection-v3 -in user-values.yaml -out new-values.yaml
```

You can also run it with Docker:

```bash
docker run \
  --rm \
  -v $(pwd):/values \
  -i sumologic/kubernetes-tools:2.19.0 \
  update-collection-v3 -in /values/user-values.yaml -out /values/new-values.yaml
```

You should have `new-values.yaml` in your working directory which can be used for the upgrade. Pay attention to the migration script
output - it may notify you of additional manual steps you need to carry out.

Before you run the upgrade command, please review the manual steps below, and carry out the ones relevant to your use case.

### Metrics migration

If you don't have metrics collection enabled, skip straight to the [next major section](#logs-migration).

The metrics migration involves one major manual step that everyone needs to do, which is upgrading kube-prometheus-stack.

#### Upgrade kube-prometheus-stack

**When?**: If you have metrics enabled at all.

Carry out the following:

- Upgrade Prometheus CRDs:

  ```bash
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.59.2/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.59.2/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.59.2/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.59.2/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.59.2/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.59.2/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.59.2/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.59.2/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
  ```

  otherwise you'll get the following error:

  ```text
  Error: UPGRADE FAILED: error validating "": error validating data: ValidationError(Prometheus.spec): unknown field "shards" in com.coreos.monitoring.v1.Prometheus.spec
  ```

- Patch the `kube-state-metrics` Deployment with new labels:

  ```bash
  kubectl get deployment \
    --namespace="${NAMESPACE}" \
    --selector 'app.kubernetes.io/name=kube-state-metrics' \
    -o json | \
  jq ". | .items[].spec.selector.matchLabels[\"app.kubernetes.io/instance\"] |= \"${HELM_RELEASE_NAME}\"" | \
  kubectl apply \
    --namespace="${NAMESPACE}" \
    --force \
    --filename -
  ```

  otherwise you'll get an error:

  ```text
  Error: UPGRADE FAILED: cannot patch "collection-kube-state-metrics" with kind Deployment: Deployment.apps "collection-kube-state-metrics" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/instance":"collection", "app.kubernetes.io/name":"kube-state-metrics"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable
  ```

- Patch the `prometheus-node-exporter` Daemonset with new labels:

```bash
kubectl get daemonset \
  --namespace "${NAMESPACE}" \
  --selector "app=prometheus-node-exporter,release=${HELM_RELEASE_NAME}" \
  -o json | \
jq ". | .items[].spec.selector.matchLabels[\"app.kubernetes.io/instance\"] |= \"${HELM_RELEASE_NAME}\"" | \
jq ". | .items[].spec.template.metadata.labels[\"app.kubernetes.io/instance\"] |= \"${HELM_RELEASE_NAME}\"" | \
jq ". | .items[].spec.selector.matchLabels[\"app.kubernetes.io/name\"] |= \"prometheus-node-exporter\"" | \
jq ". | .items[].spec.template.metadata.labels[\"app.kubernetes.io/name\"] |= \"prometheus-node-exporter\"" | \
jq '. | del(.items[].spec.selector.matchLabels["release"])' | \
jq '. | del(.items[].spec.template.metadata.labels["release"])' | \
jq '. | del(.items[].spec.selector.matchLabels["app"])' | \
jq '. | del(.items[].spec.template.metadata.labels["app"])' | \
kubectl apply \
  --namespace="${NAMESPACE}" \
  --force \
  --filename -
```

otherwise you'll get an error:

```text
Error: UPGRADE FAILED: cannot patch "collection-prometheus-node-exporter" with kind DaemonSet: DaemonSet.apps "collection-prometheus-node-exporter" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/instance":"collection", "app.kubernetes.io/name":"prometheus-node-exporter"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable
```

- If you overrode any of the `repository` keys under the `kube-prometheus-stack` key, please follow the `kube-prometheus-stack` [migration
  doc][kube-prometheus-stack-image-migration] on that.

#### Otelcol StatefulSet

**When?**: If you're using `otelcol` as the metrics metadata provider already.

Run the following command to manually delete otelcol StatefulSets:

```
kubectl delete sts --namespace=${NAMESPACE} --cascade=orphan -lapp=${HELM_RELEASE_NAME}-sumologic-otelcol-metrics
```

The reason this is necessary is that the Service name for this StatefulSet has changed, and Kubernetes forbids modification of this value on
existing StatefulSets.

#### Additional Service Monitors

**When?**: If you're using `kube-prometheus-stack.prometheus.additionalServiceMonitors`.

If you're using `kube-prometheus-stack.prometheus.additionalServiceMonitors`, you have to remove all Sumo Logic related service monitors
from the list, because they are now covered by `sumologic.metrics.serviceMonitors` configuration. This will make your configuration more
clear.

#### Remote Write Migration

**When?**: If you're using `kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite`.

If you're using `kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite` you should move all non-default configurations to
`kube-prometheus-stack.prometheus.prometheusSpec.additionalRemoteWrite` and leave
`kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite` unchanged.

In addition please ensure that `url` for all `remoteWrite` configurations starts with
`http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888` instead of
`http://$(FLUENTD_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888`

#### Custom metrics filtering and modification

**When?**: If you added extra configuration to Fluentd metrics

If you're adding extra configuration to fluentd metrics, you will likely want to do analogous modifications in OpenTelemetry.

Please look at the [Metrics modifications](./collecting-application-metrics.md#metrics-modifications) doc.

### Logs migration

If you don't have log collection enabled, skip straight to the [next major section](#tracing-migration).

#### Replacing Fluent Bit with OpenTelemetry Collector

**When?**: If you're using `fluent-bit` as the log collector, which is the default.

##### Migration with (small) data loss

On upgrade, the Fluent Bit DaemonSet will be deleted, and a new OpenTelemetry Collector Daemonset will be created. If a log file were to be
rotated between the Fluent Bit Pod disappearing and the OpenTelemetry Collector Pod starting, logs added to that file after Fluent Bit was
deleted will not be ingested. If you're ok with this minor loss of data, you can proceed without any manual intervention.

##### Migration with data duplication

If you'd prefer to ingest duplicated data for a period of time instead, with OpenTelemetry Collector and Fluent Bit running side by side,
enable the following settings:

```yaml
sumologic:
  logs:
    collector:
      allowSideBySide: true
fluent-bit:
  enabled: true
```

After the upgrade, once OpenTelemetry Collector is running, you can disable Fluent Bit again and proceed without any data loss.

##### Migration without data duplication and data loss (advanced)

If you want to migrate without losing data or ingesting duplicates, you can go with a more complex solution. The idea is to have two
separated groups of nodes. One for Fluent Bit and one for OpenTelemetry Collector.

The node group for Fluent Bit should contain all existing nodes. The second group of nodes is dedicated to all new pods.

Let's consider an example for that. We added `workerGroup: old-worker-group` label to all existing nodes, and then applied the following
configuration:

```yaml
sumologic:
  logs:
    collector:
      allowSideBySide: true
fluent-bit:
  enabled: true
  nodeSelector:
    ## run Fluent-Bit on all nodes matching label: workerGroup=old-worker-group
    workerGroup: old-worker-group
otellogs:
  daemonset:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                ## run OpenTelemetry Logs Collector on all nodes which do not match label: workerGroup=old-worker-group
                - key: workerGroup
                  operator: NotIn
                  values:
                    - old-worker-group
```

After upgrading the Helm Chart, we drained all nodes with `workerGroup: old-worker-group`, and then we set OpenTelemetry Collector as only
logs collector in the cluster by removing `fluent-bit` and `otellogs` unnecessary configuration sections.

```yaml
sumologic:
  logs:
    collector:
      allowSideBySide: true
```

#### Otelcol StatefulSet

**When?**: If you're using `otelcol` as the logs metadata provider already.

Run the following command to manually delete otelcol StatefulSets:

```
kubectl delete sts --namespace=${NAMESPACE} --cascade=orphan -lapp=${HELM_RELEASE_NAME}-sumologic-otelcol-logs
```

The reason this is necessary is that the Service name for this StatefulSet has changed, and Kubernetes forbids modification of this value on
existing StatefulSets.

#### Custom logs filtering and processing

**When?**: If you added extra configuration to Fluentd logs

If you added extra configuration to Fluentd logs, you will likely want to do analogous modifications in OpenTelemetry Collector.

Please look at the [Logs modifications](./collecting-container-logs.md#modifying-log-records) doc.

### Tracing migration

Trace collection is now enabled by default. If you'd like to keep it disabled, set:

```yaml
sumologic:
  traces:
    enabled: false
```

If you don't have tracing collection enabled, you can skip straight to the [end](#running-the-helm-upgrade) and upgrade using Helm.

#### Replace special configuration values marked by 'replace' suffix

**When?**: If you used any configuration values for traces with the `*.replace` suffix

The mechanism to replace special configuration values for traces marked by the 'replace' suffix was removed and the following special values
in the configuration are no longer automatically replaced, and they need to be changed:

- `processors.source.collector.replace`
- `processors.source.name.replace`
- `processors.source.category.replace`
- `processors.source.category_prefix.replace`
- `processors.source.category_replace_dash.replace`
- `processors.source.exclude_namespace_regex.replace`
- `processors.source.exclude_pod_regex.replace`
- `processors.source.exclude_container_regex.replace`
- `processors.source.exclude_host_regex.replace`
- `processors.resource.cluster.replace`

The above special configuration values can be replaced either to direct values or be set as reference to other parameters from
`values.yaml`.

#### OpenTelemetry Collector Deployments

- **Otelcol Deployment**

  **When?**: If tracing is enabled

  > **Warning** > `otelcol` Deployment was moved to `tracesSampler` Deployment.

  Run the following command to manually delete otelcol Deployment and ConfigMap:

  ```
  kubectl delete deployment --namespace=${NAMESPACE} --cascade=orphan ${HELM_RELEASE_NAME}-sumologic-otelcol
  kubectl delete cm --namespace=${NAMESPACE} --cascade=orphan ${HELM_RELEASE_NAME}-sumologic-otelcol
  ```

- **Otelagent DaemonSet**

  **When?**: If you're using `otelagent` (`otelagent.enabled=true`)

  > **Warning** > `otelagent` DaemonSet was replaced by `otelcolInstrumentation` **StatefulSet**.

  Run the following command to manually delete otelagent DamemonSet and ConfigMap:

  ```
  kubectl delete ds --namespace=${NAMESPACE} --cascade=orphan ${HELM_RELEASE_NAME}-sumologic-otelagent
  kubectl delete cm --namespace=${NAMESPACE} --cascade=orphan ${HELM_RELEASE_NAME}-sumologic-otelagent
  ```

- **Otelgateway Deployment**

  **When?**: If you're using `otelgateway` (`otelgateway.enabled=true`)

  > **Warning** > `otelgateway` Deployment was moved to `tracesGateway` Deployment.

  Run the following command to manually delete otelgateway Deployment and ConfigMap:

  ```
  kubectl delete deployment --namespace=${NAMESPACE} --cascade=orphan ${HELM_RELEASE_NAME}-sumologic-otelgateway
  kubectl delete cm --namespace=${NAMESPACE} --cascade=orphan ${HELM_RELEASE_NAME}-sumologic-otelgateway
  ```

### Running the helm upgrade

Once you've taken care of any manual steps necessary for your configuration, run the helm upgrade:

```bash
helm upgrade --namespace "${NAMESPACE}" "${HELM_RELEASE_NAME}" sumologic/sumologic --version=3.0.0 -f new-values.yaml
```

After you're done, please review the [full list of changes](#full-list-of-changes), as some of them may impact you even if they don't
require additional action.

### Known issues

#### Cannot delete pod if using Tailing Sidecar Operator

If you are using Tailing Sidecar Operator and see the following error:

```
Error from server: admission webhook "tailing-sidecar.sumologic.com" denied the request: there is no content to decode
```

Please try to remove the pod later.

[falco documentation]: https://github.com/falcosecurity/charts/tree/falco-2.4.2/falco
[metrics-server-upgrade]: https://github.com/bitnami/charts/tree/5b09f7a7c0d9232f5752840b6c4e5cdc56d7f796/bitnami/metrics-server#to-600
[kube-prometheus-stack-image-migration]:
  https://github.com/prometheus-community/helm-charts/tree/kube-prometheus-stack-42.1.0/charts/kube-prometheus-stack#from-41x-to-42x

#### OpenTelemetry Collector doesn't read logs from the beginning of files

This is done by design. We are not going to read logs from before the collection has been installed.

In order to keep old behavior (can result in logs duplication for some cases), please use the following configuration:

```
metadata:
  logs:
    config:
      merge:
        receivers:
          filelog/containers:
            start_at: beginning
```

## Full list of changes

- Upgrading kube-prometheus stack

  We are updating Kube-prometheus-stack to newest available version. Major feature related to that change is upgrading kube-state-metrics to
  v2

- Removing mechanism to replace values in configuration for traces marked by 'replace' suffix
- Moving direct configuration of OpenTelemetry Collector for log metadata

  Removed explicit configuration for otelcol under `metadata.logs.config`. Added option to merge configuration under
  `metadata.logs.config.merge` or overwrite default configuration `metadata.logs.config.override`

- Moving direct configuration of OpenTelemetry Collector for metrics metadata

  Removed explicit configuration for otelcol under `metadata.metrics.config`. Added option to merge configuration under
  `metadata.metrics.config.merge` or overwrite default configuration `metadata.metrics.config.override`

- Removing support for `sumologic.cluster.load_config_file`. Leaving this configuration will result in setup job failure.
- Upgrading Falco helm chart to `v2.4.2` which changed their configuration: Please validate and adjust your configuration to new version
  according to [Falco documentation]

- Moved parameters from `fluentd.logs.containers` to `sumologic.logs.container`

  - moved `fluentd.logs.containers.sourceHost` to `sumologic.logs.container.sourceHost`
  - moved `fluentd.logs.containers.sourceName` to `sumologic.logs.container.sourceName`
  - moved `fluentd.logs.contianers.sourceCategory` to `sumologic.logs.container.sourceCategory`
  - moved `fluentd.logs.containers.sourceCategoryPrefix` to `sumologic.logs.container.sourceCategoryPrefix`
  - moved `fluentd.logs.contianers.sourceCategoryReplaceDash` to `sumologic.logs.container.sourceCategoryReplaceDash`
  - moved `fluentd.logs.containers.excludeContainerRegex` to `sumologic.logs.container.excludeContainerRegex`
  - moved `fluentd.logs.containers.excludeHostRegex` to `sumologic.logs.container.excludeHostRegex`
  - moved `fluentd.logs.containers.excludeNamespaceRegex` to `sumologic.logs.container.excludeNamespaceRegex`
  - moved `fluentd.logs.containers.excludePodRegex` to `sumologic.logs.container.excludePodRegex`
  - moved `fluentd.logs.containers.sourceHost` to `sumologic.logs.container.sourceHost`
  - moved `fluentd.logs.containers.perContainerAnnotationsEnabled` to `sumologic.logs.container.perContainerAnnotationsEnabled`
  - moved `fluentd.logs.containers.perContainerAnnotationPrefixes` to `sumologic.logs.container.perContainerAnnotationPrefixes`

- Moved parameters from `fluentd.logs.kubelet` to `sumologic.logs.kubelet`

  - moved `fluentd.logs.kubelet.sourceName` to `sumologic.logs.kubelet.sourceName`
  - moved `fluentd.logs.kubelet.sourceCategory` to `sumologic.logs.kubelet.sourceCategory`
  - moved `fluentd.logs.kubelet.sourceCategoryPrefix` to `sumologic.logs.kubelet.sourceCategoryPrefix`
  - moved `fluentd.logs.kubelet.sourceCategoryReplaceDash` to `sumologic.logs.kubelet.sourceCategoryReplaceDash`
  - moved `fluentd.logs.kubelet.excludeFacilityRegex` to `sumologic.logs.kubelet.excludeFacilityRegex`
  - moved `fluentd.logs.kubelet.excludeHostRegex` to `sumologic.logs.kubelet.excludeHostRegex`
  - moved `fluentd.logs.kubelet.excludePriorityRegex` to `sumologic.logs.kubelet.excludePriorityRegex`
  - moved `fluentd.logs.kubelet.excludeUnitRegex` to `sumologic.logs.kubelet.excludeUnitRegex`

- Moved parameters from `fluentd.logs.systemd` to `sumologic.logs.systemd`

  - moved `fluentd.logs.systemd.sourceName` to `sumologic.logs.systemd.sourceName`
  - moved `fluentd.logs.systemd.sourceCategory` to `sumologic.logs.systemd.sourceCategory`
  - moved `fluentd.logs.systemd.sourceCategoryPrefix` to `sumologic.logs.systemd.sourceCategoryPrefix`
  - moved `fluentd.logs.systemd.sourceCategoryReplaceDash` to `sumologic.logs.systemd.sourceCategoryReplaceDash`
  - moved `fluentd.logs.systemd.excludeFacilityRegex` to `sumologic.logs.systemd.excludeFacilityRegex`
  - moved `fluentd.logs.systemd.excludeHostRegex` to `sumologic.logs.systemd.excludeHostRegex`
  - moved `fluentd.logs.systemd.excludePriorityRegex` to `sumologic.logs.systemd.excludePriorityRegex`
  - moved `fluentd.logs.systemd.excludeUnitRegex` to `sumologic.logs.systemd.excludeUnitRegex`

- Moved parameters from `fluentd.logs.default` to `sumologic.logs.defaultFluentd`

  - moved `fluentd.logs.default.sourceName` to `sumologic.logs.defaultFluentd.sourceName`
  - moved `fluentd.logs.default.sourceCategory` to `sumologic.logs.defaultFluentd.sourceCategory`
  - moved `fluentd.logs.default.sourceCategoryPrefix` to `sumologic.logs.defaultFluentd.sourceCategoryPrefix`
  - moved `fluentd.logs.default.sourceCategoryReplaceDash` to `sumologic.logs.defaultFluentd.sourceCategoryReplaceDash`
  - moved `fluentd.logs.default.excludeFacilityRegex` to `sumologic.logs.defaultFluentd.excludeFacilityRegex`
  - moved `fluentd.logs.default.excludeHostRegex` to `sumologic.logs.defaultFluentd.excludeHostRegex`
  - moved `fluentd.logs.default.excludePriorityRegex` to `sumologic.logs.defaultFluentd.excludePriorityRegex`
  - moved `fluentd.logs.default.excludeUnitRegex` to `sumologic.logs.defaultFluentd.excludeUnitRegex`

- Upgrading Metrics Server to `6.2.4`. In case of changing `metrics-server.*` configuration please see [upgrading section of chart's
  documentation][metrics-server-upgrade].

- Upgrading Tailing Sidecar Operator helm chart to v0.5.5. There is no breaking change if using annotations only.

- OpenTelemetry Logs Collector will read from end of file now.

  See
  [OpenTelemetry Collector doesn't read logs from the beginning of files](#opentelemetry-collector-doesnt-read-logs-from-the-beginning-of-files)
  if you want to keep old behavior.

- Changed `otelagent` from `DaemonSet` to `StatefulSet`

- Moved parameters from `otelagent.*` to `otelcolInstrumentation.*`

- Moved parameters from `otelgateway.*` to `tracesGateway.*`

- Moved parameters from `otelcol.*` to `tracesSampler.*`

- Enabled metrics and traces collection from instrumentation by default

  - changed parameter `sumologic.traces.enabled` default value from `false` to `true`

- Adding `sumologic.metrics.serviceMonitors` to avoid copying values for `kube-prometheus-stack.prometheus.additionalServiceMonitors`
  configuration

- Adding `sumologic.metrics.otelcol.extraProcessors` to make metrics modification easy

- Moved `fluentd.logs.output.logFormat` to `sumologic.logs.container.format`
