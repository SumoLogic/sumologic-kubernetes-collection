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

## Installation Steps

These steps require that no Prometheus exists. If you already have Prometheus installed select from the following options:

- [How to install if you have an existing Prometheus operator](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/docs/existingPrometheusDoc.md) 
- [How to install if you have standalone Prometheus](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/docs/standAlonePrometheus.md) 
- [How to install our Prometheus side by side with your existing Prometheus](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/docs/SideBySidePrometheus.md)

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Install the chart with release name `collection` and namespace `sumologic`

```bash
helm install sumologic/sumologic --name collection --namespace sumologic --set sumologic.endpoint=<SUMO_API_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> --set prometheus-operator.prometheus.prometheusSpec.externalLabels.cluster="<my-cluster-name>" --set sumologic.clusterName="<my-cluster-name>"
```

If you get `Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists`, run the above command with the `--no-crd-hook` flag:

```bash
helm install sumologic/sumologic --name collection --namespace sumologic --set sumologic.endpoint=<SUMO_API_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> --set prometheus-operator.prometheus.prometheusSpec.externalLabels.cluster="<my-cluster-name>" --set sumologic.clusterName="<my-cluster-name>" --no-crd-hook
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
helm install sumologic/sumologic --name my-release --namespace my-namespace -f values.yaml --set sumologic.endpoint=<SUMO_API_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> 
```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Uninstalling the Chart

To uninstall/delete the `collection` release:

```bash
helm delete collection
```
> **Tip**: Use helm delete --purge collection to completely remove the release from Helm internal storage

The command removes all the Kubernetes components associated with the chart and deletes the release.

To remove the Kubernetes secret:

```bash
kubectl delete secret sumologic
```

Then delete the associated hosted collector in the Sumo Logic UI.
