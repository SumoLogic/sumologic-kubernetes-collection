# How to install our Prometheus side by side with your existing Prometheus

When installing our Helm Chart it is possible to have more than one Prometheus server running in the same cluster. However, do note that you cannot have more than one Prometheus Operator running in the same cluster. This document will take you through the steps to set up Sumo Logic collection when you have an existing Prometheus Operator you wish to keep intact.

# Installation with Helm

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sends them to Sumo Logic.

<!-- TOC -->
- [Requirements](#requirements) 
- [Prerequisite](#prerequisite)
- [Installation Steps](#installation-steps) 
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic) 
- [Troubleshooting Installation](#troubleshooting-installation)
- [Customizing Installation](#customizing-installation)
- [Upgrade Sumo Logic Collection](#upgrading-sumo-logic-collection)
- [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection) 

<!-- /TOC -->

## Requirements

If you don’t already have a Sumo account, you can create one by clicking the Free Trial button on https://www.sumologic.com/.

The following are required to setup Sumo Logic's Kubernetes collection.

  * An [Access ID and Access Key](https://help.sumologic.com/Manage/Security/Access-Keys) with [Manage Collectors](https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities#data-management) capability.
  * Your Kubernetes cluster must allow [outbound access to Sumo Logic](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security) to setup collection. Using a proxy is not currently supported.
  * Please review our [minimum requirements](../README.md#minimum-requirements) and [support matrix](../README.md#support-matrix)


## Prerequisite

Sumo Logic Apps for Kubernetes and Explore require you to add the following [fields](https://help.sumologic.com/Manage/Fields) in the Sumo Logic UI to your Fields table schema. This is to ensure your logs are tagged with relevant metadata. This is a one time setup per Sumo Logic account.
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
* __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

The following parameter is optional, but we recommend setting it.
* __sumologic.clusterName__ - An identifier for your Kubernetes cluster. This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.

Since we are installing with an existing Prometheus Operator we must also define the following values.

* __prometheus-operator.prometheusOperator.enabled=false__ - Two operators cannot run in the same cluster at the same time, so this disables ours but preserves the existing.
* __prometheus-operator.prometheus-node-exporter.service.port=9200__ - Since node exporter uses a `NodePort` we have to change the port.
* __prometheus-operator.prometheus-node-exporter.service.targetPort=9200__ - Since node exporter uses a `NodePort` we have to change the port.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can run `helm upgrade --install` to install our chart. An example command with the minimum parameters is provided below. The following command will install the Sumo Logic chart with the release name `my-release` in the namespace your `kubectl` context is currently set to. Node that because this is installing our chart in a cluster where an existing prometheus operator is running, we need to disable our operator and update the node exporter ports.

```bash
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.prometheusOperator.enabled=false --set prometheus-operator.prometheus-node-exporter.service.port=9200 --set prometheus-operator.prometheus-node-exporter.service.targetPort=9200
```
> **Note**: This command is compatible with Helm2 or Helm3. If the release exists, it will be upgraded, otherwise it will be installed.

If you wish to install the chart in a different namespace you can do the following:

**Helm2**
```bash
helm upgrade --install my-release sumologic/sumologic --namespace=my-namespace --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.prometheusOperator.enabled=false --set prometheus-operator.prometheus-node-exporter.service.port=9200 --set prometheus-operator.prometheus-node-exporter.service.targetPort=9200
```

Please note that Helm3 no longer supports the namespace flag. You must change your `kubectl` context to the namespace you wish to install in.

**Helm3**
```bash
kubectl config set-context --current --namespace=my-namespace
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.enabled=false --set prometheus-operator.prometheusOperator.prometheus-node-exporter.service.port=9200 --set prometheus-operator.prometheus-node-exporter.service.targetPort=9200
```

## Viewing Data In Sumo Logic

Once you have completed installation, you can [install the Kubernetes App and view the dashboards](https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App_and_view_the_Dashboards) or [open a new Explore tab](https://help.sumologic.com/Solutions/Kubernetes_Solution/05Navigate_your_Kubernetes_environment) in Sumo Logic. If you do not see data in Sumo Logic, you can review our [troubleshooting guide](./Troubleshoot_Collection.md).

## Troubleshooting Installation

### Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists
If you get `Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists` on a Helm2 installation, run the above command with the `--set prometheus-operator.prometheusOperator.createCustomResource=false` flag:

```bash
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.enabled=false --set prometheus-operator.prometheusOperator.prometheus-node-exporter.service.port=9200 --set prometheus-operator.prometheus-node-exporter.service.targetPort=9200 --set prometheus-operator.prometheusOperator.createCustomResource=false
```
### Error: timed out waiting for the condition
If `helm upgrade --install` hangs, it usually means the pre-install setup job is failing and is in a retry loop. Due to a Helm limitation, errors from the setup job cannot be fed back to the `helm upgrade --install` command. Kubernetes schedules the job in a pod, so you can look at logs from the pod to see why the job is failing. First find the pod name in the namespace where the Helm chart was deployed. The pod name will contain `-setup` in the name.

```sh
kubectl get pods
```
> **Tip**: If the pod does not exist, it is possible it has been evicted.  Re-run the `helm upgrade --install` to recreate it and while that command is running, use another shell to get the name of the pod.

Get the logs from that pod:
```
kubectl logs POD_NAME -f
```
### Error: collector with name 'sumologic' does not exist
If you get `Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID`, you can safely ignore it and the installation should complete successfully. The installation process creates new [HTTP endpoints](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in your Sumo Logic account, that are used to send data to Sumo. This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](Troubleshoot_Collection.md).

## Customizing Installation
All default properties for the Helm chart can be found in our [documentation](HelmChartConfiguration.md). We recommend creating a new `values.yaml` for each Kubernetes cluster you wish to install collection on and **setting only the properties you wish to override**. Once you have customized you can use the following commands to install or upgrade. Remember to define the properties in our [requirements section](#requirements) in the `values.yaml` as well or pass them in via `--set`
  
**Helm2 or Helm3**
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

**Helm2**
```bash
helm delete my-release
```
> **Tip**: Use helm delete --purge my-release to completely remove the release from Helm internal storage

**Helm3**
```bash
helm delete my-release
```
> **Tip**: In Helm3 the default behavior is to purge history. Use --keep-history to preserve it while deleting the release.

The command removes all the Kubernetes components associated with the chart and deletes the release.

To remove the Kubernetes secret:

```bash
kubectl delete secret sumologic
```

Then delete the associated hosted collector in the Sumo Logic UI.
