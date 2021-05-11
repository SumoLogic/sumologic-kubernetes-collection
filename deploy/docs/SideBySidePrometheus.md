# How to install our Prometheus side by side with your existing Prometheus

When installing our Helm Chart it is possible to have more than one Prometheus server running in the same cluster. However, do note that you cannot have more than one Prometheus Operator running in the same cluster. This document will take you through the steps to set up Sumo Logic collection when you have an existing Prometheus Operator you wish to keep intact.

**Note**: Make sure your `Prometheus Operator` and/or `Prometheus Operator Chart` are compatible with the version used by the Collection

# Installation with Helm

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sends them to Sumo Logic.

- [Requirements](#requirements)
- [Prerequisite](#prerequisite)
- [Installation Steps](#installation-steps)
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)
- [Troubleshooting Installation](#troubleshooting-installation)
- [Customizing Installation](#customizing-installation)
- [Upgrade Sumo Logic Collection](#upgrading-sumo-logic-collection)
- [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection)

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

## Installation Steps

The Helm chart installation requires two parameter overrides:

- __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
- __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

The following parameter is optional, but we recommend setting it.

- __sumologic.clusterName__ - An identifier for your Kubernetes cluster. This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.

If you are installing the collection in a cluster that requires proxying outbound requests, please see the following [additional properties](./Installing_Behind_Proxy.md) you will need to set.

Since we are installing with an existing Prometheus Operator we must also define the following values.

- __prometheus-operator.prometheusOperator.enabled=false__ - Two operators cannot run in the same cluster at the same time, so this disables ours but preserves the existing.
- __prometheus-operator.prometheus-node-exporter.service.port=9200__ - Since node exporter uses a `NodePort` we have to change the port.
- __prometheus-operator.prometheus-node-exporter.service.targetPort=9200__ - Since node exporter uses a `NodePort` we have to change the port.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can run `helm upgrade --install` to install our chart.
An example command with the minimum parameters is provided below.
The following command will install the Sumo Logic chart with the release name
`my-release` in the namespace your `kubectl` context is currently set to.
Node that because this is installing our chart in a cluster where an existing prometheus
operator is running, we need to disable our operator and update the node exporter ports.

```bash
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set kube-prometheus-stack.prometheusOperator.enabled=false --set kube-prometheus-stack.prometheus-node-exporter.service.port=9200 --set kube-prometheus-stack.prometheus-node-exporter.service.targetPort=9200
```

> **Note**: If the release exists, it will be upgraded, otherwise it will be installed.

If you wish to install the chart in a different existing namespace you can do the following:

```bash
helm upgrade --install my-release sumologic/sumologic --namespace=my-namespace --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set kube-prometheus-stack.prometheusOperator.enabled=false --set kube-prometheus-stack.prometheus-node-exporter.service.port=9200 --set kube-prometheus-stack.prometheus-node-exporter.service.targetPort=9200
```

If the namespace does not exist, you can add the `--create-namespace` flag.

```bash
helm upgrade --install my-release sumologic/sumologic \
    --namespace=my-namespace \
    --set sumologic.accessId=<SUMO_ACCESS_ID> \
    --set sumologic.accessKey=<SUMO_ACCESS_KEY> \
    --set sumologic.clusterName="<MY_CLUSTER_NAME>" \
    --set kube-prometheus-stack.prometheusOperator.enabled=false \
    --set kube-prometheus-stack.prometheus-node-exporter.service.port=9200 \
    --set kube-prometheus-stack.prometheus-node-exporter.service.targetPort=9200 \
    --create-namespace
```

If you are installing the helm chart in Openshift platform, you can do the following:

```bash
helm upgrade --install my-release sumologic/sumologic \
    --namespace=my-namespace \
    --set sumologic.accessId=<SUMO_ACCESS_ID> \
    --set sumologic.accessKey=<SUMO_ACCESS_KEY> \
    --set sumologic.clusterName="<MY_CLUSTER_NAME>" \
    --set kube-prometheus-stack.prometheus-node-exporter.service.port=9200 \
    --set kube-prometheus-stack.prometheus-node-exporter.service.targetPort=9200 \
    --set kube-prometheus-stack.prometheusOperator.prometheusInstanceNamespaces=[my-namespace] \
    --set sumologic.scc.create=true \
    --set fluent-bit.securityContext.privileged=true
```

## Viewing Data In Sumo Logic

Once you have completed installation, you can
[install the Kubernetes App and view the dashboards][sumo-k8s-app-dashboards]
or [open a new Explore tab] in Sumo Logic.
If you do not see data in Sumo Logic, you can review our
[troubleshooting guide](./Troubleshoot_Collection.md).

[sumo-k8s-app-dashboards]: https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App_and_view_the_Dashboards
[open a new Explore tab]: https://help.sumologic.com/Observability_Solution/Kubernetes_Solution/Navigate_your_Kubernetes_environment

## Troubleshooting Installation

### Error: timed out waiting for the condition

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

### Error: collector with name 'sumologic' does not exist

If you get

```
Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID
```

you can safely ignore it and the installation should complete successfully.
The installation process creates new [HTTP endpoints](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source)
in your Sumo Logic account, that are used to send data to Sumo.
This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](Troubleshoot_Collection.md).

## Customizing Installation

All default properties for the Helm chart can be found in our
[documentation](../helm/sumologic/README.md).
We recommend creating a new `values.yaml` for each Kubernetes cluster you wish
to install collection on and **setting only the properties you wish to override**.
Once you have customized you can use the following commands to install or upgrade.
Remember to define the properties in our [requirements section](#requirements)
in the `values.yaml` as well or pass them in via `--set`

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml
```

> **Tip**: To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Upgrading Sumo Logic Collection

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

If you no longer have your `values.yaml` from the first installation or do not remember the options you added via `--set` you can run the following to see the values for the currently installed helm chart. For example, if the release is called `my-release` you can run the following.

```bash
helm get values my-release
```

If something goes wrong, or you want to go back to the previous version,
you can [rollback changes using helm](https://helm.sh/docs/helm/helm_rollback/):

```
helm history my-release
helm rollback my-release <REVISION-NUMBER>
```

## Uninstalling Sumo Logic Collection

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
