# How to install if you have standalone Prometheus

__NOTE__: The Sumo Logic Kubernetes collection process does not support collecting metrics from scaling Prometheus replicas. If you are running multiple Prometheus replicas, please follow our [Side-by-Side](SideBySidePrometheus.md) instructions.

<!-- TOC -->
- [Prerequisite](#prerequisite)
- [Install Sumo Logic Helm Chart](#install-sumo-logic-helm-chart) 
- [Update Existing Prometheus](#update-existing-prometheus) 
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)

<!-- /TOC -->

This document will walk you through how to setup Sumo Logic Kubernetes collection when you already have Prometheus running, not using the Prometheus Operator. In these steps, you will modify your installed Prometheus to add in the minimum configuration that Sumo Logic needs. If you are using the Prometheus Operator, please refer to our guide on installing with an existing [Prometheus Operator](./existingPrometheusDoc.md).

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

## Install Sumo Logic Helm Chart

The Helm chart installation requires two parameter overrides:
* __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

The following parameter is optional, but we recommend setting it.
* __sumologic.clusterName__ - An identifier for your Kubernetes cluster.  This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can run `helm upgrade --install` to install our chart.  An example command with the minimum parameters is provided below.  The following command will install the Sumo Logic chart with the release name `my-release` in the namespace your `kubectl` context is currently set to. The below command also disables the `prometheus-operator` sub-chart since we will be modifying the existing prometheus operator install.

```bash
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.enabled=false
```
> **Note**: This command is compatible with Helm2 or Helm3.  If the release exists, it will be upgraded, otherwise it will be installed.

If you wish to install the chart in a different namespace you can do the following:

**Helm2**
```bash
helm upgrade --install my-release sumologic/sumologic --namespace=my-namespace --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.enabled=false
```

Please note that Helm3 no longer supports the namespace flag. You must change your `kubectl` context to the namespace you wish to install in.

**Helm3**
```bash
kubectl config set-context --current --namespace=my-namespace
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.enabled=false
```

## Update Existing Prometheus

First, Download the Prometheus Operator `prometheus-overrides.yaml` by running

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v1.0/deploy/helm/prometheus-overrides.yaml
```

Next, make the following modifications to the `remoteWrite` section of the `prometheus-overrides.yaml` file:

* `writeRelabelConfigs:` change to `write_relabel_configs:`
* `sourceLabels:` change to `source_labels:`
*  Modify remote URLs in the `remoteWrite` section of the `prometheus-overrides.yaml` file

The URLs in `remoteWrite` section of the `prometheus-overrides.yaml` file uses `env` variables which need to be changed to point to the correct location.

- Replace `$(CHART)` with the `release name-namespace` that you have used while installing the Sumo Logic helm chart.
- Replace `$(NAMESPACE)` with the namespace where Prometheus is running.

For example:\
If you have installed the Sumo Logic helm chart with release name `collection` in the `sumologic` namespace and Prometheus is running in the `prometheus` namespace:
```
`$(CHART).$(NAMESPACE)` will be replaced by `collection-sumologic.prometheus`
```

Next, copy the modified `remoteWrite` section of the `prometheus-overrides.yaml` file to your Prometheus configuration file’s `remote_write` section, as per the documentation [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)

Then run the following command to find the existing Prometheus pod.
```
kubectl get pods | grep prometheus
```

Finally, delete the existing Prometheus pod so that Kubernetes will respawn it with the updated configuration.
```
kubectl delete pods <prometheus_pod_name>

```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Viewing Data In Sumo Logic

Once you have completed installation, you can [install the Kubernetes App and view the dashboards](https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App_and_view_the_Dashboards) or [open a new Explore tab](https://help.sumologic.com/Solutions/Kubernetes_Solution/05Navigate_your_Kubernetes_environment) in Sumo Logic. If you do not see data in Sumo Logic, you can review our [troubleshooting guide](./Troubleshoot_Collection.md).