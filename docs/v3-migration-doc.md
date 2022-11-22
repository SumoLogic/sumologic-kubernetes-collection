# Kubernetes Collection `v3.0.0` - Breaking Changes

- [Changes](#changes)
- [How to upgrade](#how-to-upgrade)
  - [Requirements](#requirements)
  - [Manual steps](#manual-steps)
    - [Upgrade kube-prometheus-stack](#upgrade-kube-prometheus-stack)
  - [Replace special configuration values marked by 'replace' suffix](#replace-special-configuration-values-marked-by-replace-suffix)

Based on the feedback from our users, we will be introducing several changes
to the Sumo Logic Kubernetes Collection solution.

In this document we detail the changes as well as the exact steps for migration.

## Changes

- Upgrading kube-prometheus stack

  We are updating Kube-prometheus-stack to newest available version.
  Major feature related to that change is upgrading kube-state-metrics to v2

- Removing mechanism to replace values in configuration for traces marked by 'replace' suffix

## How to upgrade

### Requirements

- `helm3`
- `kubectl`
- `jq`

### Manual steps

1. Perform required manual steps:
    - [Upgrade kube-prometheus-stack](#upgrade-kube-prometheus-stack)
2. Delete the following StatefulSets (otelcol):
    - [Otelcol StatefulSets](#otelcol-statefulsets)

#### Upgrade kube-prometheus-stack

Upgrade of kube-prometheus-stack is a breaking change and requires manual steps:

- Upgrading prometheus CRDs:

  ```bash
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.58.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.58.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.58.0/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.58.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.58.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.58.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.58.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
  kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.58.0/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
  ```

  due to:

  ```text
  Error: UPGRADE FAILED: error validating "": error validating data: ValidationError(Prometheus.spec): unknown field "shards" in com.coreos.monitoring.v1.Prometheus.spec
  ```

- Patching `kube-state-metrics` deployment:

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

  due to:

  ```text
  Error: UPGRADE FAILED: cannot patch "collection-kube-state-metrics" with kind Deployment: Deployment.apps "collection-kube-state-metrics" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/instance":"collection", "app.kubernetes.io/name":"kube-state-metrics"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable
  ```

### Replace special configuration values marked by 'replace' suffix

Mechanism to replace special configuration values for traces marked by 'replace' suffix was removed and following special values in configuration are no longer automatically replaced and they need to be changed:

- `exporters.otlptraces.endpoint.replace`
- `exporters.otlpmetrics.endpoint.replace`
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
- `exporters.sumologic.source_name.replace`
- `exporters.sumologic.source_category.replace`

Above special configuration values can be replaced either to direct values or be set as reference to other parameters form `values.yaml`.

#### Otelcol StatefulSets

If you're using `otelcol` as the logs/metrics metadata provider, please run one or both of the following commands to manually delete StatefulSets in helm chart v2 before upgrade:

  ```
  kubectl delete sts --namespace=my-namespace --cascade=false my-release-sumologic-otelcol-logs
  kubectl delete sts --namespace=my-namespace --cascade=false my-release-sumologic-otelcol-metrics
  ```
