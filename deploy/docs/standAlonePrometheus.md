# How to install if you have standalone Prometheus

__NOTE__: The Sumo Logic Kubernetes collection process does not support collecting metrics from scaling Prometheus replicas. If you are running multiple Prometheus replicas, please follow our [Side-by-Side](SideBySidePrometheus.md) instructions.

- [Requirements](#requirements)
- [Prerequisite](#prerequisite)
- [Install Sumo Logic Helm Chart](#install-sumo-logic-helm-chart)
- [Update Existing Prometheus](#update-existing-prometheus)
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)
- [Customizing Installation](#customizing-installation)
- [Upgrading Sumo Logic Collection](#upgrading-sumo-logic-collection)
- [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection)

This document will walk you through how to set up Sumo Logic Kubernetes collection
when you already have Prometheus running, not using the Prometheus Operator.
In these steps, you will modify your installed Prometheus to add in the
minimum configuration that Sumo Logic needs.
If you are using the Prometheus Operator, please refer to our guide on installing
with an existing [Prometheus Operator](./existingPrometheusDoc.md).

## Requirements

If you don’t already have a Sumo account, you can create one by clicking the Free Trial button on https://www.sumologic.com/.

The following are required to setup Sumo Logic's Kubernetes collection.

- An [Access ID and Access Key](https://help.sumologic.com/Manage/Security/Access-Keys) with [Manage Collectors](https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities#data-management) capability.
- Please review our [minimum requirements](../README.md#minimum-requirements) and [support matrix](../README.md#support-matrix)

To get an idea of the resources this chart will require to run on your cluster, you can reference our [performance doc](./Performance.md).

## Prerequisite

Sumo Logic Apps for Kubernetes and Explore require you to add the following [fields](https://help.sumologic.com/Manage/Fields#Manage_fields) in the Sumo Logic UI to your Fields table schema. This is to ensure your logs are tagged with relevant metadata. This is a one time setup per Sumo Logic account.

- cluster
- container
- deployment
- host
- namespace
- node
- pod
- service

## Install Sumo Logic Helm Chart

The Helm chart installation requires two parameter overrides:

- __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
- __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

To get an idea of the resources this chart will require to run on your cluster, you can reference our [performance doc](./Performance.md).

If you are installing the collection in a cluster that requires proxying outbound requests, please see the following [additional properties](./Installing_Behind_Proxy.md) you will need to set.

The following parameter is optional, but we recommend setting it.

- __sumologic.clusterName__ - An identifier for your Kubernetes cluster. This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`. Whitespaces in the cluster name will be replaced with dashes.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can run `helm upgrade --install` to install our chart.
An example command with the minimum parameters is provided below.
The following command will install the Sumo Logic chart with the release name `my-release` in the namespace your `kubectl` context is currently set to.
The below command also disables the `kube-prometheus-stack` sub-chart since we will be modifying the existing prometheus operator install.

```bash
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set kube-prometheus-stack.enabled=false
```

> __Note__: If the release exists, it will be upgraded, otherwise it will be installed.

If you wish to install the chart in a different existing namespace you can do the following:

```bash
helm upgrade --install my-release sumologic/sumologic --namespace=my-namespace --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set kube-prometheus-stack.enabled=false
```

If the namespace does not exist, you can add the `--create-namespace` flag.

```bash
helm upgrade --install my-release sumologic/sumologic \
  --set sumologic.accessId=<SUMO_ACCESS_ID> \
  --set sumologic.accessKey=<SUMO_ACCESS_KEY> \
  --set sumologic.clusterName="<MY_CLUSTER_NAME>" \
  --set kube-prometheus-stack.enabled=false \
  --create-namespace
```

If you are installing the Helm chart in OpenShift platform, you can do the following:

```bash
helm upgrade --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  --set sumologic.accessId=<SUMO_ACCESS_ID> \
  --set sumologic.accessKey=<SUMO_ACCESS_KEY> \
  --set sumologic.clusterName="<MY_CLUSTER_NAME>" \
  --set kube-prometheus-stack.enabled=false \
  --set sumologic.scc.create=true \
  --set fluent-bit.securityContext.privileged=true
```

## Update Existing Prometheus

First, generate the Prometheus Operator `prometheus-overrides.yaml` by running

```bash
 # using kubectl
 kubectl run tool \
  -it --quiet --rm \
  --restart=Never -n sumologic \
  --image sumologic/kubernetes-tools:2.9.0 \
  -- template-dependency kube-prometheus-stack > prometheus-overrides.yaml

 # or using Docker
 docker run -it --rm \
  sumologic/kubernetes-tools:2.9.0 \
  template-dependency kube-prometheus-stack > prometheus-overrides.yaml
```

Next, change the `remoteWrite` section of the `prometheus-overrides.yaml` file to use snake_case instead of camelCase:

- `writeRelabelConfigs:` change to `write_relabel_configs:`
- `sourceLabels:` change to `source_labels:`
- `remoteTimeout:` change to `remote_timeout:`

Next, replace the environment variables used in the `remoteWrite` section of the `prometheus-overrides.yaml` file:

- Replace `$(FLUENTD_METRICS_SVC)` with the Helm release name that you used while installing the Sumo Logic Helm chart, followed by `-sumologic-fluentd-metrics`.
- Replace `$(NAMESPACE)` with the namespace where Sumo Logic Helm chart is running.

For example:\
If you have installed the Sumo Logic Helm chart with release name `collection` and it is running in the `sumologic` namespace,

```bash
`$(FLUENTD_METRICS_SVC).$(NAMESPACE)` will be replaced by `collection-sumologic-fluentd-metrics.sumologic`
```

Next, copy the modified `remoteWrite` section of the `prometheus-overrides.yaml` file to your Prometheus configuration file’s `remote_write` section, as per the documentation [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)

Then run the following command to find the existing Prometheus pod.

```bash
kubectl get pods | grep prometheus
```

Finally, delete the existing Prometheus pod so that Kubernetes will respawn it with the updated configuration.

```bash
kubectl delete pods <prometheus_pod_name>
```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Viewing Data In Sumo Logic

Once you have completed installation, you can
[install the Kubernetes App and view the dashboards][sumo-k8s-app-dashboards]
or [open a new Explore tab] in Sumo Logic.
If you do not see data in Sumo Logic, you can review our
[troubleshooting guide](./Troubleshoot_Collection.md).

[sumo-k8s-app-dashboards]: https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App_and_view_the_Dashboards
[open a new Explore tab]: https://help.sumologic.com/Observability_Solution/Kubernetes_Solution/02Monitoring_Using_Kubernetes#open%C2%A0explore

## Customizing Installation

All default properties for the Helm chart can be found in our [documentation](../helm/sumologic/README.md).
We recommend creating a new `values.yaml` for each Kubernetes cluster you wish
to install collection on and __setting only the properties you wish to override__.
Once you have customized you can use the following commands to install or upgrade.
Remember to define the properties in our [requirements section](#requirements)
in the `values.yaml` as well or pass them in via `--set`

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml
```

> __Tip__: To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Upgrading Sumo Logic Collection

__Note, if you are upgrading to version 1.x of our collection from a version before 1.x, please see our [migration guide](v1_migration_doc.md).__

To upgrade our Helm chart to a newer version, you must first run update your local Helm repo.

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

If you no longer have your `values.yaml` from the first installation or do not remember the options you added via `--set` you can run the following to see the values for the currently installed Helm chart. For example, if the release is called `my-release` you can run the following.

```bash
helm get values my-release
```

If something goes wrong, or you want to go back to the previous version,
you can [rollback changes using helm](https://helm.sh/docs/helm/helm_rollback/):

```bash
helm history my-release
helm rollback my-release <REVISION-NUMBER>
```

Finally, you can repeat the steps to [Update Existing Prometheus](#update-existing-prometheus) with the latest.

## Uninstalling Sumo Logic Collection

To uninstall/delete the Helm chart:

```bash
helm delete my-release
```

> __Helm3 Tip__: In Helm3 the default behavior is to purge history. Use --keep-history to preserve it while deleting the release.ease.

The command removes all the Kubernetes components associated with the chart and deletes the release.

To remove the Kubernetes secret:

```bash
kubectl delete secret sumologic
```

Then delete the associated hosted collector in the Sumo Logic UI.
