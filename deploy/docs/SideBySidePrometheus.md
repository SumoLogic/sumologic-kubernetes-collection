# How to install our Prometheus side by side with your existing Prometheus

When installing our Helm Chart it is possible to have more than one Prometheus server running in the same cluster.

However, do note that you must either limit the scope of the interaction of the Prometheus Operator
(by setting option `kube-prometheus-stack.prometheusOperator.namespaces.additional`)
or disable Prometheus Operator in Sumo Logic's Kubernetes collection
(existing Prometheus Operator must have `namespace`, in which Sumo Logic's Kubernetes collection is installed,
in the scope of its interaction, please pay attention to following flags set for Prometheus Operator:
`namespaces`, `deny-namespaces` and `prometheus-instance-namespaces`,
for details please [Prometheus Operator documentation][prometheus_operator_doc]).

This document will take you through the steps to set up Sumo Logic collection when you have an existing Prometheus Operator you wish to keep intact.

**Note**: Make sure your `Prometheus Operator` and/or `Prometheus Operator Chart` are compatible with the version used by the Collection

[prometheus_operator_doc]: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/operator.md

## Installation with Helm

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sends them to Sumo Logic.

- [Installation with Helm](#installation-with-helm)
  - [Requirements](#requirements)
  - [Prerequisite](#prerequisite)
  - [Installation Steps](#installation-steps)
    - [Additional configuration settings](#additional-configuration-settings)
  - [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)
  - [Troubleshooting Installation](#troubleshooting-installation)
    - [Error: timed out waiting for the condition](#error-timed-out-waiting-for-the-condition)
    - [Error: collector with name 'sumologic' does not exist](#error-collector-with-name-sumologic-does-not-exist)
  - [Customizing Installation](#customizing-installation)
  - [Upgrading Sumo Logic Collection](#upgrading-sumo-logic-collection)
  - [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection)

### Requirements

If you don’t already have a Sumo account, you can create one by clicking the Free Trial button on https://www.sumologic.com/.

The following are required to setup Sumo Logic's Kubernetes collection.

- An [Access ID and Access Key](https://help.sumologic.com/docs/manage/security/access-keys/) with [Manage Collectors](https://help.sumologic.com/docs/manage/users-roles/roles/role-capabilities#data-management) capability.
- Please review our [minimum requirements](../README.md#minimum-requirements) and [support matrix](../README.md#support-matrix)

To get an idea of the resources this chart will require to run on your cluster, you can reference our [performance doc](./Performance.md).

### Prerequisite

Sumo Logic Apps for Kubernetes and Explore require you to add the following [fields](https://help.sumologic.com/docs/manage/fields/#manage-fields) in the Sumo Logic UI to your Fields table schema. This is to ensure your logs are tagged with relevant metadata. This is a one time setup per Sumo Logic account.

- cluster
- container
- deployment
- host
- namespace
- node
- pod
- service

### Installation Steps

The Helm chart installation requires two parameter overrides:

- **sumologic.accessId** - Sumo [Access ID](https://help.sumologic.com/docs/manage/security/access-keys/).
- **sumologic.accessKey** - Sumo [Access key](https://help.sumologic.com/docs/manage/security/access-keys/).

The following parameter is optional, but we recommend setting it.

- **sumologic.clusterName** - An identifier for your Kubernetes cluster. This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.

If you are installing the collection in a cluster that requires proxying outbound requests, please see the following [additional properties](./Installing_Behind_Proxy.md) you will need to set.

If you are installing with an existing Prometheus Operator you must also define the following values:

- **kube-prometheus-stack.prometheusOperator.enabled=false** - this disables ours but preserves the existing.
- **kube-prometheus-stack.prometheus-node-exporter.service.port=9200** - Since node exporter uses a `NodePort` we have to change the port.
- **kube-prometheus-stack.prometheus-node-exporter.service.targetPort=9200** - Since node exporter uses a `NodePort` we have to change the port.

If you are installing with limiting the scope of the interaction of Prometheus Operator you must also define the following values:

- **kube-prometheus-stack.prometheusOperator.namespaces.additional={my-namespace}** - this limits scope for our Prometheus Operator only to the `my-namespace` namespace
- **prometheus-operator.prometheus-node-exporter.service.port=9200** - Since node exporter uses a `NodePort` we have to change the port.
- **prometheus-operator.prometheus-node-exporter.service.targetPort=9200** - Since node exporter uses a `NodePort` we have to change the port.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can prepare `values.yaml` with configuration.
An example file with the minimum confiuration is provided below.

If you are installing with an existing Prometheus Operator:

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
kube-prometheus-stack:
  prometheusOperator:
    enabled: false
  prometheus-node-exporter:
    service:
      port: 9200
      targetPort: 9200
```

If you are installing with limiting the scope of the interaction of Prometheus Operator:

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
kube-prometheus-stack:
  prometheusOperator:
    namespaces:
      additional:
        - ${NAMESPACE}
  prometheus-node-exporter:
    service:
      port: 9200
      targetPort: 9200
```

Now you can run `helm upgrade --install` to install our chart.
The following command will install the Sumo Logic chart with the release name `my-release`
in the namespace your `kubectl` context is currently set to.

```bash
helm upgrade --install my-release sumologic/sumologic \
    -f values.yaml
```

> **Note**: If the release exists, it will be upgraded, otherwise it will be installed.

If you wish to install the chart in a different existing namespace you should add `--namespace` flag, for example:

```bash
helm upgrade --install my-release sumologic/sumologic \
    --namespace=my-namespace \
    -f values.yaml
```

If the namespace does not exist, you can add the `--create-namespace` flag, for example:

```bash
helm upgrade --install my-release sumologic/sumologic \
    --namespace=my-namespace \
    --create-namespace \
    -f values.yaml
```

If you are installing the Sumo Logic Kubernetes collection Helm Chart in Openshift platform you can follow one of two paths:

- Using the solution with limiting the scope of the interaction of our Prometheus Operator

  Add the following configuration to your `values.yaml`

  ```yaml
  sumologic:
    scc:
      create: true
  kube-prometheus-stack:
    prometheusOperator:
      namespaces:
        additional:
          - my-namespace
    prometheus-node-exporter:
      service:
        port: 9200
        targetPort: 9200
  fluent-bit:
    securityContext:
      privileged: true
  tailing-sidecar-operator:
    scc:
      create: true
  ```

  so it will look the following way:

  ```yaml
  sumologic:
    accessId: ${SUMO_ACCESS_ID}
    accessKey: ${SUMO_ACCESS_KEY}
    clusterName: ${MY_CLUSTER_NAME}
    scc:
      create: true
  kube-prometheus-stack:
    prometheusOperator:
      namespaces:
        additional:
          - my-namespace
    prometheus-node-exporter:
      service:
        port: 9200
        targetPort: 9200
  fluent-bit:
    securityContext:
      privileged: true
  tailing-sidecar-operator:
    scc:
      create: true
  ```

  and then run the following command:

  ```bash
  helm upgrade --install my-release sumologic/sumologic \
      --namespace=my-namespace \
      -f values.yaml
  ```

- Using existing Prometheus Operator which is by default available in `openshift-monitoring` namespace

  Add the following configuration to your `values.yaml`

  ```yaml
  sumologic:
    scc:
      create: true
  kube-prometheus-stack:
    prometheus-node-exporter:
      service:
        port: 9200
        targetPort: 9200
    prometheusOperator:
      enabled: false
  fluent-bit:
    securityContext:
      privileged: true
  tailing-sidecar-operator:
    scc:
      create: true
  ```

  so it will look like the following way:

  ```yaml
  sumologic:
    accessId: ${SUMO_ACCESS_ID}
    accessKey: ${SUMO_ACCESS_KEY}
    clusterName: ${MY_CLUSTER_NAME}
    scc:
      create: true
  kube-prometheus-stack:
    prometheus-node-exporter:
      service:
        port: 9200
        targetPort: 9200
    prometheusOperator:
      enabled: false
  fluent-bit:
    securityContext:
      privileged: true
  tailing-sidecar-operator:
    scc:
      create: true
  ```

  and then run the following command:

  ```bash
  helm upgrade --install my-release sumologic/sumologic \
      --namespace=my-namespace \
      -f values.yaml
  ```

**Note**: If you are installing the Sumo Logic Kubernetes collection Helm Chart in Openshift 4.9 or newer and you want to use existing Prometheus Operator
you need to add Prometheus init container configuration to the `values.yaml` in following form:

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      initContainers:
        - name: "init-config-reloader"
          env:
            - name: FLUENTD_METRICS_SVC
              valueFrom:
                configMapKeyRef:
                  name: sumologic-configmap
                  key: fluentdMetrics
            - name: NAMESPACE
              valueFrom:
                configMapKeyRef:
                  name: sumologic-configmap
                  key: fluentdNamespace
```

Example command which can be used to deploy in OpenShift 4.9 or newer when existing Prometheus Operator is in use
(`values.yaml` must contain above configuration for init container):

```bash
helm upgrade --install my-release sumologic/sumologic \
    --namespace=openshift-monitoring \
    -f values.yaml
```

#### Additional configuration settings

##### Additional configuration for Kubernetes 1.25 or newer

`PodSecurityPolicy` is unavailable in v1.25+ so to install Helm Chart in Kubernetes 1.25 or newer you need to add following setting to your configuration:

```yaml
kube-prometheus-stack:
  global:
    rbac:
      pspEnabled: false
  kube-state-metrics:
    podSecurityPolicy:
      enabled: false
  prometheus-node-exporter:
    rbac:
      pspEnabled: false
```

##### Additional configuration for AKS 1.25

To install Helm Chart in AKS 1.25 you need to disable `PodSecurityPolicy` which is unavailable in v1.25+ and
to you use falco you need set newer version of falco image in configuration:

```yaml
kube-prometheus-stack:
  global:
    rbac:
      pspEnabled: false
  kube-state-metrics:
    podSecurityPolicy:
      enabled: false
  prometheus-node-exporter:
    rbac:
      pspEnabled: false
falco:
  image:
    registry: 'public.ecr.aws'
    repository: 'falcosecurity/falco'
    tag: '0.33.1'
```

### Viewing Data In Sumo Logic

Once you have completed installation, you can
[install the Kubernetes App and view the dashboards][sumo-k8s-app-dashboards]
or [open a new Explore tab] in Sumo Logic.
If you do not see data in Sumo Logic, you can review our
[troubleshooting guide](./Troubleshoot_Collection.md).

[sumo-k8s-app-dashboards]: https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app
[open a new Explore tab]: https://help.sumologic.com/docs/observability/kubernetes/monitoring#open-explore

### Troubleshooting Installation

#### Error: timed out waiting for the condition

If `helm upgrade --install` hangs, it usually means the pre-install setup job
is failing and is in a retry loop.
Due to a Helm limitation, errors from the setup job cannot be fed back to the
`helm upgrade --install` command.
Kubernetes schedules the job in a pod, so you can look at logs from the pod to see why the job is failing.
First find the pod name in the namespace where the Helm chart was deployed.
The pod name will contain `-setup` in the name.

```sh
kubectl get pods
```

> **Tip**: If the pod does not exist, it is possible it has been evicted.
> Re-run the `helm upgrade --install` to recreate it and while that command is running,
> use another shell to get the name of the pod.

Get the logs from that pod:

```
kubectl logs POD_NAME -f
```

#### Error: collector with name 'sumologic' does not exist

If you get

```
Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID
```

you can safely ignore it and the installation should complete successfully.
The installation process creates new [HTTP endpoints](https://help.sumologic.com/docs/send-data/hosted-collectors/http-source)
in your Sumo Logic account, that are used to send data to Sumo.
This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](Troubleshoot_Collection.md).

### Customizing Installation

All default properties for the Helm chart can be found in our
[documentation](../helm/sumologic/README.md).
We recommend creating a new `values.yaml` for each Kubernetes cluster you wish
to install collection on and **setting only the properties you wish to override**.
Once you have customized you can use the following commands to install or upgrade.
Remember to define the properties in our [requirements section](#requirements)
in the `values.yaml` as well

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml
```

> **Tip**: To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

### Upgrading Sumo Logic Collection

**Note, if you are upgrading to version 1.x of our collection from a version before 1.x, please see our [migration guide](v1_migration_doc.md).**

To upgrade our helm chart to a newer version, you must first run update your local helm repo.

```bash
helm repo update
```

Next, you can run `helm upgrade --install` to upgrade to that version. The following upgrades the current version of `my-release` to the latest.

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml
```

If you wish to upgrade to a specific version, you can use the `--version` flag.

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml --version=1.0.0
```

**Note:** If you no longer have your `values.yaml` from the first installation
or do not remember the options you added via `--set` you can run the following to see the values for the currently installed helm chart.
For example, if the release is called `my-release` you can run the following.

```bash
helm get values my-release
```

If something goes wrong, or you want to go back to the previous version,
you can [rollback changes using helm](https://helm.sh/docs/helm/helm_rollback/):

```
helm history my-release
helm rollback my-release <REVISION-NUMBER>
```

### Uninstalling Sumo Logic Collection

To uninstall/delete the Helm chart:

```bash
helm delete my-release
```

> **Helm3 Tip**: In Helm3 the default behavior is to purge history. Use --keep-history to preserve it while deleting the release.ease.

The command removes all the Kubernetes components associated with the chart and deletes the release.

To remove the Kubernetes secret:

```bash
kubectl delete secret sumologic
```

Then delete the associated hosted collector in the Sumo Logic UI.
