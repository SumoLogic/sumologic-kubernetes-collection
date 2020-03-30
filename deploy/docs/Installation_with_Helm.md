# Installation with Helm

Note: the following steps assume you are installing using Helm 2.  Use of Helm 3 is not yet supported.

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

The Helm chart installation requires two parameter overrides:
* __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

## Installation Steps

These steps require that no Prometheus exists. If you already have Prometheus installed select from the following options:

- [How to install if you have an existing Prometheus operator](./existingPrometheusDoc.md) 
- [How to install if you have standalone Prometheus](./standAlonePrometheus.md) 
- [How to install our Prometheus side by side with your existing Prometheus](./SideBySidePrometheus.md)

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Install the chart with release name `collection` and namespace `sumologic`

```bash
helm install sumologic/sumologic --name collection --namespace sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>"
```

If you get `Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists`, run the above command with the `--no-crd-hook` flag:

```bash
helm install sumologic/sumologic --name collection --namespace sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --no-crd-hook
```

If you get `Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID` This error occurs when you have run the installation step at least once before. The installation process creates new [HTTP endpoints](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in your Sumo Logic account, which are used to send data into Sumo. This error occurs if the endpoints had already been created by an earlier run of the installation process. This error is really a warning, and the installation process should complete successfully.

__NOTE__ `Google Kubernetes Engine (GKE)` uses Container-Optimized OS (COS) as the default operating system for its worker node pools. COS is a security-enhanced operating system that limits access to certain parts of the underlying OS. Because of this security constraint, Falco cannot insert its kernel module to process events for system calls. However, COS provides the ability to use extended Berkeley Packet Filter (eBPF) to supply the stream of system calls to the Falco engine. eBPF is currently only supported on GKE and COS. For more information see [Installing Falco](https://falco.org/docs/installation/).

To install on `GKE`, use the provided override file to customize your configuration and uncomment the following lines in the `values.yaml` file referenced below:

```
ebpf:
  enabled: true
```

To customize your configuration:

- Download the `values.yaml` file by running:

```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v0.17/deploy/helm/sumologic/values.yaml > values.yaml
```

- Modify the `values.yaml` file with your customizations, then apply the configuration using the following command:

```bash
helm install sumologic/sumologic --name collection --namespace sumologic -f values.yaml --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> --set sumologic.clusterName=<MY_CLUSTER_NAME> -f values.yaml
```

#### To install the chart with a different release name or namespace:

```bash
helm install sumologic/sumologic --name my-release --namespace my-namespace -f values.yaml --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> --set sumologic.clusterName=<MY_CLUSTER_NAME>
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
