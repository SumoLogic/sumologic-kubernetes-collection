# Prometheus

Prometheus is crucial part of the metrics pipeline. It is also a complicated and powerful tool. In Kubernetes specifically, it's also often
managed by Prometheus Operator and a set of custom resources. It's possible that you already have some part of the K8s Prometheus stack
installed, and would like to make use of it. This document describes how to deal with all the possible cases.

**NOTE:** In this document we assume that `${NAMESPACE}` represents namespace in which the Sumo Logic Kubernetes Collection is going to be
installed.

<!-- TOC -->

- [Prometheus](#prometheus)
  - [No Prometheus in the cluster](#no-prometheus-in-the-cluster)
  - [Prometheus Operator in the cluster](#prometheus-operator-in-the-cluster)
    - [Custom Resource Definition compatibility](#custom-resource-definition-compatibility)
    - [Installing Sumo Logic Prometheus Operator side by side with existing Operator](#installing-sumo-logic-prometheus-operator-side-by-side-with-existing-operator)
      - [Set Sumo Logic Prometheus Operator to observe installation namespace](#set-sumo-logic-prometheus-operator-to-observe-installation-namespace)
    - [Using existing Operator to create Sumo Logic Prometheus instance](#using-existing-operator-to-create-sumo-logic-prometheus-instance)
      - [Disable Sumo Logic Prometheus Operator](#disable-sumo-logic-prometheus-operator)
    - [Prepare Sumo Logic Configuration to work with existing Operator](#prepare-sumo-logic-configuration-to-work-with-existing-operator)
    - [Using existing Kube Prometheus Stack](#using-existing-kube-prometheus-stack)
      - [Build Prometheus Configuration](#build-prometheus-configuration)
  - [Horizontal Scaling (Sharding)](#horizontal-scaling-sharding)
  - [Troubleshooting](#troubleshooting)
    - [UPGRADE FAILED: failed to create resource: Internal error occurred: failed calling webhook "prometheusrulemutate.monitoring.coreos.com"](#upgrade-failed-failed-to-create-resource-internal-error-occurred-failed-calling-webhook-prometheusrulemutatemonitoringcoreoscom)
    - [Error: unable to build kubernetes objects from release manifest: error validating "": error validating data: ValidationError(Prometheus.spec)](#error-unable-to-build-kubernetes-objects-from-release-manifest-error-validating--error-validating-data-validationerrorprometheusspec)

## No Prometheus in the cluster

If you don't have Prometheus or Kube Prometheus Stack installed in your cluster there is not much you need to worry about. There is no
special configuration required, unless you want to have
[Custom Application Metrics](https://help.sumologic.com/docs/send-data/kubernetes/collecting-metrics#filtering-metrics) or
[Custom Kubernetes Metrics](https://help.sumologic.com/docs/send-data/kubernetes/collecting-metrics/#kubernetes-metrics), but these steps
can be performed after initial installation.

## Prometheus Operator in the cluster

If you already have Prometheus operator in your cluster, the necessary changes depend on the compatibility between Prometheus Operator used
in your cluster and Prometheus Operator used by Sumo Logic Kubernetes Collection.

In that situation we support three scenarios:

1. Installing Sumo Logic Prometheus Operator side by side with existing Operator

   **NOTE:** This is possible if Custom Resource Definitions in the cluster are compatible with those required by Sumo Logic, or there is
   possibility to install Custom Resource Definition which will be accepted by all Prometheus Operators

1. Using existing Operator to create Sumo Logic Prometheus instance

   **NOTE:** This is possible if Custom Resource Definitions in the cluster are compatible with those required by Sumo Logic, or there is
   possibility to install Custom Resource Definition which will be accepted by all Prometheus Operators

1. Using existing Kube Prometheus Stack

### Custom Resource Definition compatibility

Sumo Logic collection requires CRD version of `v0.59.2` or newer. If you are using a newer version in your cluster, you probably don't have
to do anything. Otherwise, ensure that the Custom Resource Definitions won't break your existing Prometheus Operators and then apply them
using the following commands:

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

Unfortunately there is no easy way to check which Custom Resource Definition is applied on the cluster. The only symptom is failing
installation with the following or similar error (containing `com.coreos.monitoring.v1`).

```text
Error: unable to build kubernetes objects from release manifest: error validating "": error validating data: ValidationError(Prometheus.spec): unknown field "hostNetwork" in com.coreos.monitoring.v1.Prometheus.spec
```

Required Custom Resource Definitions are listed in [Kube Prometheus Stack repository][kube-prometheus-stack-repo]

[kube-prometheus-stack-repo]:
  https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#upgrading-an-existing-release-to-a-new-major-version

### Installing Sumo Logic Prometheus Operator side by side with existing Operator

You can have multiple Prometheus Operators in the cluster, but you need to ensure that they do not observe the same namespace(s). **Every**
Operator should have `${NAMESPACE}` as part of `--deny-namespaces` argument or shouldn't have it as part of `--namespaces` argument, for
example:

```shell
$ kubectl get deployment -l app=kube-prometheus-stack-operator -oyaml -A
apiVersion: v1
items:
- apiVersion: apps/v1
  kind: Deployment
...
      spec:
        containers:
        - args:
...
          - --deny-namespaces=${NAMESPACE},some-namespace
...
- apiVersion: apps/v1
  kind: Deployment
...
      spec:
        containers:
        - args:
...
          - --namespaces=some-namespace
...
```

#### Set Sumo Logic Prometheus Operator to observe installation namespace

Limit observed namespaces to `${NAMESPACE}` in `user-values.yaml`

```yaml
kube-prometheus-stack:
  prometheusOperator:
    namespaces:
      releaseNamespace: true
```

After that, please follow to
[Prepare Sumo Logic Configuration to work with existing Operator](#prepare-sumo-logic-configuration-to-work-with-existing-operator)

### Using existing Operator to create Sumo Logic Prometheus instance

Ensure that the `${NAMESPACE}` is being watched by your operator. For exactly one operator it should be part of `--namespaces` argument or
shouldn't be part of `--deny-namespaces` argument.

In the following example both operators are going to watch `${NAMESPACE}` (which is incorrect, but shows two ways to observe the namespace):

```shell
$ kubectl get deployment -l app=kube-prometheus-stack-operator -oyaml -A
apiVersion: v1
items:
- apiVersion: apps/v1
  kind: Deployment
...
      spec:
        containers:
        - args:
...
          - --deny-namespaces=some-namespace
...
- apiVersion: apps/v1
  kind: Deployment
...
      spec:
        containers:
        - args:
...
          - --namespaces=${NAMESPACE},other-namespace
...
```

#### Disable Sumo Logic Prometheus Operator

If the Sumo Logic Prometheus should be managed by external Operator, you need to disable installation of Sumo Logic Operator by merging the
following configuration to your `user-values.yaml`.

```yaml
kube-prometheus-stack:
  prometheusOperator:
    enabled: false
```

Next, please follow to
[Prepare Sumo Logic Configuration to work with existing Operator](#prepare-sumo-logic-configuration-to-work-with-existing-operator)

### Prepare Sumo Logic Configuration to work with existing Operator

:construction: Describe how to use node-exporter from different operators

Now, build Kube Prometheus Stack configuration for Sumo Logic:

- Change Node Exporter port to avoid conflicts with other Prometheuses

  ```yaml
  kube-prometheus-stack:
    prometheus-node-exporter:
      service:
        port: 9200
        targetPort: 9200
  ```

  > **NOTE:** Change port to other value if Prometheus Node Exporter Pods are in Pending state and you see the following warning in Events:
  >
  > ```txt
  > Events:
  >   Type     Reason            Age                    From               Message
  >   ----     ------            ----                   ----               -------
  >   Warning  FailedScheduling  13m (x249 over 4h25m)  default-scheduler  0/3 nodes are available: 1 node(s) didn't have free ports for the requested pod ports, 2 node(s) didn't match Pod's node affinity/selector.
  > ```

ln total, the configuration for `user-values.yaml` should look like the following:

```yaml
kube-prometheus-stack:
  prometheusOperator:
    namespaces:
      releaseNamespace: true
  prometheus-node-exporter:
    service:
      port: 9200
      targetPort: 9200
```

Prometheus configuration is ready and now you can proceed with installation.

### Using existing Kube Prometheus Stack

We recommend to install Sumo Logic Kubernetes Collection before configuring Prometheus, but you need to disable Kube Prometheus Stack used
by Sumo Logic Collection first.

```yaml
kube-prometheus-stack:
  enabled: false
```

#### Build Prometheus Configuration

If there is no common CRDs for Prometheus Operators or you want to use only one instance of Prometheus (which is not the instance used by
Sumo Logic), you should merge our configuration with the configuration used in your Operator. You need to ensure that the following values
are correctly added to your Kube Prometheus Stack configuration:

- ServiceMonitors configuration:

  - `sumologic.metrics.ServiceMonitors` and `sumologic.metrics.additionalServiceMonitors` to `prometheus.additionalServiceMonitors`

- RemoteWrite configuration:

  - `kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite` to `prometheus.prometheusSpec.remoteWrite` or
    `prometheus.prometheusSpec.additionalRemoteWrite`

  **Note:** `kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite` and
  `kube-prometheus-stack.prometheus.prometheusSpec.additionalRemoteWrite` are being use to generate list of endpoints in Metadata Pod, so
  ensure that:

  - they are always in sync with the current configuration and endpoints starts with.
  - url always starts with `http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888`

  Alternatively, you can list endpoints in `metadata.metrics.config.additionalEndpoints`:

  ```yaml
  metadata:
    metrics:
      config:
        additionalEndpoints:
          - /prometheus.metrics
          # - ...
  ```

- Env Variables configuration:

  - `kube-prometheus-stack.prometheus.prometheusSpec.initContainers` to `prometheus.prometheusSpec.initContainers`
  - `kube-prometheus-stack.prometheus.prometheusSpec.containers` to `prometheus.prometheusSpec.containers`

  with the following modification:

  - replace

    ```yaml
    valueFrom:
      configMapKeyRef:
        name: sumologic-configmap
        key: metadataMetrics
    ```

    with

    ```yaml
    value: ${METADATA}
    ```

    where `${METADATA}` is content of `metadataMetrics` key from `sumologic-configmap` ConfigMap within `${NAMESPACE}`:

    ```yaml
    apiVersion: v1
    data:
      metadataLogs: collection-sumologic-metadata-logs
      metadataMetrics: collection-sumologic-remote-write-proxy
      metadataNamespace: sumologic
    kind: ConfigMap
    metadata:
      annotations:
        meta.helm.sh/release-name: collection
        meta.helm.sh/release-namespace: sumologic
      creationTimestamp: "2023-01-11T15:05:57Z"
      labels:
        app.kubernetes.io/managed-by: Helm
        chart: sumologic-3.0.0-beta.1
        heritage: Helm
        release: collection
      name: sumologic-configmap
      namespace: sumologic
      resourceVersion: "509256"
      uid: 1a916815-84ab-48a4-82d1-91e4df29daae
    ```

  - replace

    ```yaml
    valueFrom:
      configMapKeyRef:
        name: sumologic-configmap
        key: metadataNamespace
    ```

    with

    ```yaml
    value: ${NAMESPACE}
    ```

After all of the changes, your Kube Prometheus Stack should look like the following:

```yaml
prometheus:
  additionalServiceMonitors:
    # values copied from sumologic.metrics.ServiceMonitors
  prometheusSpec:
    initContainers:
      # values copied from kube-prometheus-stack.prometheus.prometheusSpec.initContainers
    containers:
      # values copied from kube-prometheus-stack.prometheus.prometheusSpec.containers
    additionalRemoteWrite:
      # values copied from kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite
```

Prometheus configuration is ready. Apply the changes on the cluster.

## Horizontal Scaling (Sharding)

Horizontal scaling, also known as sharding, is supported by setting up a configuration parameter which allows running several prometheus
servers in agent mode to gather your data.

To define the number of shards, configure the following parameter under the `kube-prometheus-stack` subchart in the `user-values.yaml` file:

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      shards: 3
```

For configuring an existing prometheus deployment, please add the following to your `user-values.yaml` file:

```yaml
prometheusSpec:
  shards: 3
```

**Note:** Sharding prometheus servers will cause recording rule metrics which require global aggregations (across nodes) to stop working
which may also impact the Kubernetes dashboard.

## Troubleshooting

### UPGRADE FAILED: failed to create resource: Internal error occurred: failed calling webhook "prometheusrulemutate.monitoring.coreos.com"

If you receive the above error, you can take the following steps and then repeat the `helm upgrade` command.

```bash
kubectl delete  validatingwebhookconfigurations.admissionregistration.k8s.io kube-prometheus-stack-admission
kubectl delete  MutatingWebhookConfiguration  kube-prometheus-stack-admission
```

### Error: unable to build kubernetes objects from release manifest: error validating "": error validating data: ValidationError(Prometheus.spec)

Refer to [Custom Resource Definition compatibility](#custom-resource-definition-compatibility)
