TODO
Also would be nice if there was a configuration section like this: https://github.com/helm/charts/tree/master/stable/nginx-ingress#configuration

# Installation with Helm

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sends them to Sumo Logic.

<!-- TOC -->
 
- [Prerequisite](#prerequisite)
- [Installation Steps](#installation-steps) 
- [Uninstalling the Chart](#uninstalling-the-chart) 

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

The Helm chart installation requires two parameter overrides:
* __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

The following parameter is optional, but we recommend setting it.
* __sumologic.clusterName__ - An identifier for your Kubernetes cluster.  Default is `kubernetes`.

## Installation Steps

These steps require that no Prometheus exists. If you already have Prometheus installed select from the following options:

- [How to install if you have an existing Prometheus operator](./existingPrometheusDoc.md) 
- [How to install if you have standalone Prometheus](./standAlonePrometheus.md) 
- [How to install our Prometheus side by side with your existing Prometheus](./SideBySidePrometheus.md)

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can run `helm install` to install our chart.  An example command with the minimum parameters is provided below for Helm2 and Helm3.

Helm2
```bash
helm install sumologic/sumologic --name my-release --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>"
```

Helm3
```bash
helm install my-release sumologic/sumologic  --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>"
```

Once you have completed installation, you can [install the Kubernetes App and view the dashboards](https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App_and_view_the_Dashboards) or [open a new Explore tab](https://help.sumologic.com/Solutions/Kubernetes_Solution/05Navigate_your_Kubernetes_environment) in in Sumo Logic.

### Troubleshooting
If you get `Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists` on a Helm2 installation, run the above command with the `--no-crd-hook` flag:

```bash
helm install sumologic/sumologic --name my-release --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --no-crd-hook
```

If you get `Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID`, you can safely ignore it and the installation should complete successfully. The installation process creates new [HTTP endpoints](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in your Sumo Logic account, that are used to send data to Sumo. This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](Troubleshoot_Collection.md).

### Customization
All default properties for the Helm chart can be found in our [documentation](HelmChartConfigiuration.md).

To customize your configuration:

- Download the `values.yaml` file by running:

```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v0.17/deploy/helm/sumologic/values.yaml > values.yaml
```

- Modify the `values.yaml` file with your customizations, then apply the configuration using the following command:

Helm2
```bash
helm install sumologic/sumologic --name my-release -f values.yaml --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> --set sumologic.clusterName=<MY_CLUSTER_NAME> -f values.yaml
```

Helm3
```bash
helm install my-release sumologic/sumologic -f values.yaml --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> --set sumologic.clusterName=<MY_CLUSTER_NAME>
```

> **Tip**: To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Uninstalling Sumo Logic Collection

To uninstall/delete the `collection` release:

Helm2
```bash
helm delete collection
```
> **Tip**: Use helm delete --purge collection to completely remove the release from Helm internal storage

Helm3
```bash
helm delete collection
```
> **Tip**: In Helm3 the default behavior is to purge history. Use --keep-history to preserve it while deleting the release.

The command removes all the Kubernetes components associated with the chart and deletes the release.

To remove the Kubernetes secret:

```bash
kubectl delete secret sumologic
```

Then delete the associated hosted collector in the Sumo Logic UI.
