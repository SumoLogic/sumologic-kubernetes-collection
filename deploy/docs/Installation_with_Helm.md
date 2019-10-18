# Installation with Helm

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sends them to Sumo Logic.

<!-- TOC -->
 
- [Prerequisite](#prerequisite)
- [Installation Steps](#installation-steps) 
- [Uninstalling the Chart](#uninstalling-the-chart) 

<!-- /TOC -->

## Prerequisite

Sumo Logic Apps for Kubernetes and Explore require you to add the following [fields](https://help.sumologic.com/Manage/Fields) in the Sumo Logic UI to your Fields table schema. This is to ensure your logs are tagged with relevant metadata.
- cluster
- container
- deployment
- host
- namespace
- node
- pod
- service

The Helm chart installation requires three parameter overrides:
* __sumologic.endpoint__ - See [API endpoints](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security) for details.
* __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

How to install when no Prometheus exists
How to install if you have an existing Prometheus operator
Install Fluentd, Fluent-bit, and Falco
Overwrite Prometheus Remote Write Configuration
Merge Prometheus Remote Write Configuration
How to install if you have standalone Prometheus
How to install our Prometheus side by side with your existing Prometheus

## Installation Steps

These steps require that no Premotheus exists. If you already have prometheus installed select from the following options:

- [How to install if you have an existing Prometheus operator](#how-to-install-if-you-have-an-existing-prometheus-operator) 
- [How to install if you have standalone Prometheus](#how-to-install-if-you-have-standalone-prometheus) 
- [How to install our Prometheus side by side with your existing Prometheus](#how-to-install-our-prometheus-side-by-side-with-your-existing-prometheus)

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Install the chart with release name `collection` and namespace `sumologic`

```bash
helm install sumologic/sumologic --name collection --namespace sumologic --set sumologic.endpoint=<SUMO_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>
```

If you get `Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists`, run

```bash
helm install sumologic/sumologic --name collection --namespace sumologic --set sumologic.endpoint=<SUMO_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> --no-crd-hook
```

To customize your configuration, download the values.yaml file by running

```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/sumologic/values.yaml
```

NOTE: If you need to install the chart with a different release name or namespace you will need to override some configuration fields for both Prometheus and fluent-bit. We recommend using an override file due to the number of fields that need to be overridden. In the following command, replace the `<RELEASE-NAME>` and `<NAMESPACE>` variables with your values and then run it to download the override file with your replaced values:

```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/sumologic/values.yaml | \
sed 's/\-sumologic.sumologic'"/-sumologic.<NAMESPACE>/g" | \
sed 's/\- sumologic'"/- <NAMESPACE>/g" | \
sed 's/\collection'"/<RELEASE-NAME>/g" > values.yaml
```

For example, if your release name is `my-release` and namespace is `my-namespace`:
```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/sumologic/values.yaml | \
sed 's/\-sumologic.sumologic'"/-sumologic.my-namespace/g" | \
sed 's/\collection'"/my-release/g" > values.yaml
```

Make any changes to the `values.yaml` file as needed, and run the following to install the chart with the override file.

```bash
helm install sumologic/sumologic --name my-release --namespace my-namespace -f values.yaml --set sumologic.endpoint=<SUMO_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> 
```

If you would like to use a different cluster name than the default `kubernetes`, add this to the `helm install` command:
```
--set prometheus-operator.prometheus.prometheusSpec.externalLabels.cluster="<my-cluster-name>" --set sumologic.clusterName="<my-cluster-name>"
```

## Uninstalling the Chart

To uninstall/delete the `collection` release:

```bash
helm delete collection
```
> **Tip**: Use helm delete --purge collection to completely remove the release from Helm internal storage

The command removes all the Kubernetes components associated with the chart and deletes the release.
