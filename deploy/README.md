# Deployment Guide

This page has instructions for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic. See our [documentation guide](https://help.sumologic.com/Solutions/Kubernetes_Solution) for details on our Kubernetes Solution.

<!-- TOC -->

- [Deployment Guide](#deployment-guide)
	- [Solution overview](#solution-overview)
	- [Minimum Requirements](#minimum-requirements)
	- [Installation with Helm](#installation-with-helm) 
		- [Prerequisite](#prerequisite)
		- [How to install when no Prometheus exists](#how-to-install-when-no-prometheus-exists) 
		- [How to install if you have an existing Prometheus operator](#how-to-install-if-you-have-an-existing-prometheus-operator) 
			- [Default steps](#default-steps) 
			- [Manual configuration steps](#manual-configuration-steps) 
		- [How to install if you have standalone Prometheus](#how-to-install-if-you-have-standalone-prometheus) 
		- [Uninstalling the Chart](#uninstalling-the-chart) 
	- [Non Helm Installation](#non-helm-installation) 
		- [Before you start](#before-you-start) 
		- [Step 1: Create Sumo Fields, a collector, and deploy Fluentd](#step-1-create-sumo-fields-a-collector-and-deploy-fluentd) 
			- [Automatic Source Creation and Setup Script](#automatic-source-creation-and-setup-script) 
				- [Parameters](#parameters) 
				- [Environment variables](#environment-variables) 
		- [Manual Source Creation and Setup](#manual-source-creation-and-setup) 
			- [Create a Hosted Collector and an HTTP Source](#create-a-hosted-collector-and-an-http-source) 
			- [Deploy Fluentd](#deploy-fluentd) 
				- [Use default configuration](#use-default-configuration) 
				- [Customize configuration](#customize-configuration) 
			- [Verify the pods are running](#verify-the-pods-are-running) 
		- [Step 2: Configure Prometheus](#step-2-configure-prometheus) 
			- [Missing metrics for `controller-manager` or `scheduler`](#missing-metrics-for-`controller-manager`-or-`scheduler`) 
			- [Additional configuration options](#additional-configuration-options) 
			- [Metrics](#metrics) 
				- [Filter metrics](#filter-metrics) 
				- [Trim and relabel metrics](#trim-and-relabel-metrics) 
			- [Custom Metrics](#custom-metrics) 
				- [Step 1: Expose a `/metrics` endpoint on your service](#step-1-expose-a-`/metrics`-endpoint-on-your-service) 
				- [Step 2: Set up a service monitor so that Prometheus pulls the data](#step-2-set-up-a-service-monitor-so-that-prometheus-pulls-the-data) 
				- [Step 3: Create a new HTTP source in Sumo Logic.](#step-3-create-a-new-http-source-in-sumo-logic.) 
				- [Step 4: Update the metrics.conf FluentD Configuration](#step-4-update-the-metrics.conf-fluentd-configuration) 
				- [Step 5: Update the prometheus-overrides.yaml file to forward the metrics to FluentD.](#step-5-update-the-prometheus-overrides.yaml-file-to-forward-the-metrics-to-fluentd.) 
		- [Step 3: Deploy FluentBit](#step-3-deploy-fluentbit) 
		- [Step 4: Deploy Falco](#step-4-deploy-falco) 
	- [Tear down](#tear-down) 
	- [Adding Additional FluentD Plugins](#adding-additional-fluentd-plugins)
- [Troubleshooting Collection](#troubleshooting-collection)
	- [Namespace configuration](#namespace-configuration) 
	- [Gathering logs](#gathering-logs) 
		- [Fluentd Logs](#fluentd-logs) 
		- [Prometheus Logs](#prometheus-logs) 
		- [Send data to Fluentd stdout instead of to Sumo](#send-data-to-fluentd-stdout-instead-of-to-sumo) 
	- [Gathering metrics](#gathering-metrics) 
		- [Check the `/metrics` endpoint](#check-the-`/metrics`-endpoint) 
		- [Check the Prometheus UI](#check-the-prometheus-ui) 
		- [Check Prometheus Remote Storage](#check-prometheus-remote-storage) 
		- [Check FluentBit and FluentD output metrics](#check-fluentbit-and-fluentd-output-metrics) 
	- [Common Issues](#common-issues) 
		- [Pod stuck in `ContainerCreating` state](#pod-stuck-in-`containercreating`-state) 
		- [Missing `kubelet` metrics](#missing-`kubelet`-metrics) 
			- [- Enable the `authenticationTokenWebhook` flag in the cluster](#--enable-the-`authenticationtokenwebhook`-flag-in-the-cluster) 
			- [2. Disable the `kubelet.serviceMonitor.https` flag in the Prometheus operator](#2.-disable-the-`kubelet.servicemonitor.https`-flag-in-the-prometheus-operator) 
		- [Missing `kube-controller-manager` or `kube-scheduler` metrics](#missing-`kube-controller-manager`-or-`kube-scheduler`-metrics) 

<!-- /TOC -->

## Solution overview

The diagram below illustrates the components of the Kubernetes collection solution.

![solution](/images/k8s_collection_diagram.png)

* **K8S API Server**. Exposes API server metrics.
* **Scheduler.** Makes Scheduler metrics available on an HTTP metrics port.
* **Controller Manager.** Makes Controller Manager metrics available on an HTTP metrics port.
* **node-exporter.** The `node_exporter` add-on exposes node metrics, including CPU, memory, disk, and network utilization.
* **kube-state-metrics.** Listens to the Kubernetes API server; generates metrics about the state of the deployments, nodes, and pods in the cluster; and exports the metrics as plaintext on an HTTP endpoint listen port.
* **Prometheus deployment.** Scrapes the metrics exposed by the `node-exporter` add-on for Kubernetes and the `kube-state-metric`s component; writes metrics to a port on the Fluentd deployment.
* **Fluentd deployment.** Forwards logs and metrics to HTTP sources on a hosted collector. Includes multiple Fluentd plugins that parse and format the metrics and enrich them with metadata.
* **Events Fluentd deployment.** Forwards events to an HTTP source on a hosted collector.

## Minimum Requirements

Name | Version
-------- | -----
K8s | 1.10+
Helm | 2.11+

## Support Matrix

The following table displays the tested Kubernetes and Helm versions.

Name | Version
-------- | -----
K8s with EKS | 1.13.8
|| 1.11.10
K8s with Kops | 1.13.10-k8s<br>1.13.0-kops
|| 1.12.8-k8s<br>1.12.2-kops
||1.10.13-k8s<br>1.10.0-kops
K8s with GKE | 1.12.8-gke.10<br>1.12.7-gke.25<br>1.11.10-gke.5
K8s with AKS | 1.12.8
Helm | 2.14.13 (Linux)
kubectl | 1.15.0

The following matrix displays the tested package versions for our Helm chart.

Sumo Logic Helm Chart | Prometheus Operator | Fluent Bit | Falco
|:-------- |:-------- |:-------- |:--------
0.6.0 | 6.2.1 | 2.4.4 | 1.0.5

## Installation with Helm

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sends them to Sumo Logic.

### Prerequisite

Before installing the chart, you'll need to set up the following [fields](https://help.sumologic.com/Manage/Fields) in the Sumo Logic UI. This is to ensure your logs are tagged with relevant metadata.
- cluster
- container
- deployment
- host
- namespace
- node
- pod
- service

### How to install when no Prometheus exists

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

### How to install if you have an existing Prometheus operator

Run the following to download the `values.yaml` file

```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/sumologic/values.yaml
```

Edit the `values.yaml` file so `prometheus-operator.enabled = false`, and run

```bash
helm install sumologic/sumologic --name collection --namespace sumologic -f values.yaml --set sumologic.endpoint=<SUMO_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> 
```

If you already have a customized remote write configuration you’ll need to make some manual changes, see the [manual configuration](#manual-configuration-steps) steps, otherwise follow the [default](#default-steps) steps.

#### Default steps

Run the following to update the [remote write configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write) of the prometheus operator by installing with the prometheus overrides file we provide.

```bash
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.6.0/deploy/helm/prometheus-overrides.yaml
```

Then run

```bash
helm upgrade prometheus-operator stable/prometheus-operator -f prometheus-overrides.yaml
```

#### Manual configuration steps

Helm supports providing multiple configuration files, priority will be given to the last (right-most) file specified. You can obtain your current prometheus configuration by running

```bash
helm get values prometheus-operator > current-values.yaml
```

Any section of `current-values.yaml` that conflicts with sections of our `prometheus-overrides.yaml` will have to be removed from the `prometheus-overrides.yaml` file and appended to `current-values.yaml` in relevant sections. For any config that doesn’t conflict, you can leave them in `prometheus-overrides.yaml`. Then run

```bash
helm upgrade prometheus-operator stable/prometheus-operator -f current-values.yaml -f prometheus-overrides.yaml
```

### How to install if you have standalone Prometheus

Update your Prometheus configuration file’s `remote_write` section, as per the documentation [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write), by taking the `remoteWrite` section of the `prometheus-overrides.yaml` file, and making the following changes:

* `writeRelabelConfigs:` change to `write_relabel_configs:`
* `sourceLabels:` change to `source_labels:`

### Uninstalling the Chart

To uninstall/delete the `collection` release:

```bash
helm delete collection
```
> **Tip**: Use helm delete --purge collection to completely remove the release from Helm internal storage

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Non Helm Installation

### Before you start

* If you haven’t already done so, create your Kubernetes cluster. Verify that you can access the cluster with `kubectl`.
* Verify that the cluster DNS service is enabled. For more information, see [DNS](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/#dns) in Kubernetes documentation.
* Verify that you are in the correct context. You can check your current context and set your desired context with:
```
kubectl config current-context
kubectl config use-context DESIRED_CONTEXT_NAME
```

__NOTE__ These instructions assume that Prometheus is not already running on your Kubernetes cluster.

### Step 1: Create Sumo Fields, a Collector, and deploy Fluentd

In this step you create a Sumo Logic Hosted Collector with a set of HTTP Sources to receive your Kubernetes data; creates Kubernetes secrets for the HTTP sources created; and deploy Fluentd using a Sumo-provided .yaml manifest.

First, you'll need to set up the relevant [fields](https://help.sumologic.com/Manage/Fields) in the Sumo Logic UI. This is to ensure your logs will be tagged with the correct metadata.
- cluster
- container
- deployment
- host
- namespace
- node
- pod
- service

#### Automatic Source Creation and Setup Script

This approach requires access to the Sumo Logic Collector API. It will create a Hosted Collector and multiple HTTP Source endpoints and pre-populate Kubernetes secrets detailed in the manual steps below.

```sh
curl -s https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/docker/setup/setup.sh \
  | bash -s - [-c <collector_name>] [-k <cluster_name>] [-n <namespace>] [-a <boolean>] [-d <boolean>] [-y <boolean>] <api_endpoint> <access_id> <access_key>
```

__NOTE__ This script will be executed in bash and requires [jq command-line JSON parser](https://stedolan.github.io/jq/download/) to be installed.

##### Parameters

* __-c &lt;collector_name&gt;__ - optional. Name of Sumo Collector that will be created. If not specified, it will be named as `kubernetes-<timestamp>`
* __-k &lt;cluster_name&gt;__ - optional. Name of the Kubernetes cluster that will be attached to logs and events as metadata. If not specified, it will be named as `kubernetes-<timestamp>`. For metrics, specify the cluster name in the `prometheus-overrides.yaml` provided for the prometheus operator; further details in [step 2](#step-2-configure-prometheus).
* __-n &lt;namespace&gt;__ - optional. Name of the Kubernetes namespace in which to deploy resources. If not specified, the namespace will default to `sumologic`.
* __-a &lt;boolean&gt;__ - optional. Set this to true if you want to deploy with the latest alpha version. If not specified, the latest release will be deployed.
* __-d &lt;boolean&gt;__ - optional. Set this to false to only set up the Sumo Collector and Sources and download the YAML file, but not to deploy so you can customize the YAML file, such as configuring fields for [events](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/fluent-plugin-events/README.md#fluent-plugin-events). If not specified, the default configuration will deploy.
* __-y &lt;boolean&gt;__ - optional. When -d is set to false you can also set this to false to not download the YAML file. If not specified, the YAML file will be downloaded.
* __&lt;api_endpoint&gt;__ - required. See [API endpoints](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security) for details.
* __&lt;access_id&gt;__ - required. Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __&lt;access_key&gt;__ - required. Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

##### Environment variables
The parameters for Collector name, cluster name and namespace may also be passed in via environment variables instead of script arguments. If the script argument is supplied that trumps the environment variable.
* __SUMO_COLLECTOR_NAME__ - optional. Name of Sumo Collector that will be created. If not specified, it will be named as `kubernetes-<timestamp>`
* __KUBERNETES_CLUSTER_NAME__ - optional. Name of the Kubernetes cluster that will be attached to logs and events as metadata. If not specified, it will be named as `kubernetes-<timestamp>`. For metrics, specify the cluster name in the `prometheus-overrides.yaml` provided for the prometheus operator; further details in [step 2](#step-2-configure-prometheus).
* __SUMO_NAMESPACE__ - optional. Name of the Kubernetes namespace in which to deploy resources. If not specified, the namespace__ will default to `sumologic`

__Note:__ The script will generate a YAML file (`fluentd-sumologic.yaml`) with all the deployed Kuberentes resources on disk. Save this file for easy teardown and redeploy of the resources.

### Manual Source Creation and Setup

This is a manual alternative approach to the automatic script if you don't have API access or need customized configuration, such as reusing an existing collector.

#### Create a Hosted Collector and an HTTP Source

In this step you create a Sumo Logic Hosted Collector with a set of HTTP Sources to receive your Kubernetes data.

Create a Hosted Collector, following the instructions on [Configure a Hosted Collector](https://help.sumologic.com/03Send-Data/Hosted-Collectors/Configure-a-Hosted-Collector) in Sumo help. If you already have a Sumo Hosted Collector that you want to use, skip this step.

Create nine HTTP Sources under the collector you created in the previous step, one for each of the Kubernetes components that report metrics in this solution, one for logs, and one for events:

* api-server-metrics
* kubelet-metrics
* controller-manager-metrics
* scheduler-metrics
* kube-state-metrics
* node-exporter-metrics
* default-metrics
* logs
* events

Follow the instructions on [HTTP Logs and Metrics Source](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) to create the Sources, with the following additions:

* **Naming the sources.** You can assign any name you like to the Sources, but it’s a good idea to assign a name to each Source that reflects the Kubernetes component from which it receives data. For example, you might name the source that receives API Server metrics “api-server-metrics”.
* **HTTP Source URLs.** When you configure each HTTP Source, Sumo will display the URL of the HTTP endpoint. Make a note of the URL. You will use it when you configure the Kubernetes service secrets to send data to Sumo.

#### Deploy Fluentd

In this step you will deploy Fluentd using a Sumo-provided .yaml manifest. This step also creates Kubernetes secrets for the HTTP Sources created in the previous step.

Run the following command to create namespace `sumologic`

```sh
kubectl create namespace sumologic
```

Run the following command to create a Kubernetes secret containing the 9 HTTP source URLs previously created.

```sh
kubectl -n sumologic create secret generic sumologic \
  --from-literal=endpoint-metrics=$ENDPOINT_METRICS \
  --from-literal=endpoint-metrics-apiserver=$ENDPOINT_METRICS_APISERVER \
  --from-literal=endpoint-metrics-kube-controller-manager=$ENDPOINT_METRICS_KUBE_CONTROLLER_MANAGER \
  --from-literal=endpoint-metrics-kube-scheduler=$ENDPOINT_METRICS_KUBE_SCHEDULER \
  --from-literal=endpoint-metrics-kube-state=$ENDPOINT_METRICS_KUBE_STATE \
  --from-literal=endpoint-metrics-kubelet=$ENDPOINT_METRICS_KUBELET \
  --from-literal=endpoint-metrics-node-exporter=$ENDPOINT_METRICS_NODE_EXPORTER \
  --from-literal=endpoint-logs=$ENDPOINT_LOGS \
  --from-literal=endpoint-events=$ENDPOINT_EVENTS
```

##### Use default configuration

If you don't need to customize the configuration apply the `fluentd-sumologic.yaml` manifest with the following command:

```sh
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/fluentd-sumologic.yaml.tmpl | \
sed 's/\$NAMESPACE'"/sumologic/g" | \
kubectl -n sumologic apply -f -
```

##### Customize configuration

If you need to customize the configuration there are two commands to run. First, get the `fluentd-sumologic.yaml` manifest with following command:

```sh
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/fluentd-sumologic.yaml.tmpl | \
sed 's/\$NAMESPACE'"/sumologic/g" >> fluentd-sumologic.yaml
```

Next, customize the provided YAML file. Our [plugin](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/fluent-plugin-events/README.md#fluent-plugin-events) allows you to configure fields for events. Once done run the following command to apply the `fluentd-sumologic.yaml` manifest.

```sh
kubectl -n sumologic apply -f fluentd-sumologic.yaml
```

The manifest will create the Kubernetes resources required by Fluentd.


#### Verify the pods are running

```sh
kubectl -n sumologic get pod
```

### Step 2: Configure Prometheus

In this step, you will configure the Prometheus server to write metrics to Fluentd.

Install Helm:

*Note the following steps are one way to install Helm, but in order to ensure property security, please be sure to review the [Helm documentation.](https://helm.sh/docs/using_helm/#securing-your-helm-installation)*

Download Helm to generate the yaml files necessary to deploy by running

```bash
brew install kubernetes-helm
```

Download the Prometheus Operator `prometheus-overrides.yaml` by running

```bash
$ cd /path/to/helm/charts/  
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.6.0/deploy/helm/prometheus-overrides.yaml
```

In `prometheus-overrides.yaml`, edit to define a unique cluster identifier. The default value of the cluster field in the externalLabels section of prometheus-overrides.yaml is kubernetes. If you will be deploying the metric collection solution on multiple Kubernetes clusters, you will want to use a unique identifier for each. For example, you might use “Dev”, “Prod”, and so on.

Before installing `prometheus-operator`, edit `prometheus-overrides.yaml` to define a unique cluster identifier. The default value of the `cluster` field in the `externalLabels` section of `prometheus-overrides.yaml` is `kubernetes`. If you will be deploying the metric collection solution on multiple Kubernetes clusters, you will want to use a unique identifier for each. For example, you might use “Dev”, “Prod”, and so on.

__NOTE__ It’s fine to change the value of the `cluster` field, but don’t change the field name (key).

__NOTE__ If you plan to install Prometheus in a different namespace than you deployed Fluentd to in Step 1, or you have an existing Prometheus you plan to apply our configuration to running in a different namespace,  please update the remote write API configuration to use the full service URL like, `http://collection-sumologic.sumologic.svc.cluster.local:9888`.

You can also [Filter metrics](#filter-metrics) and [Trim and relabel metrics](#trim-and-relabel-metrics) in `prometheus-overrides.yaml`.

Install `prometheus-operator` by generating the yaml files using Helm:

```bash
$ helm template stable/prometheus-operator --name prometheus-operator --set dryRun=true -f prometheus-overrides.yaml > prometheus.yaml
$ kubectl apply -f prometheus.yaml
```

Verify `prometheus-operator` is running:

```sh
kubectl -n sumologic logs prometheus-prometheus-operator-prometheus-0 prometheus -f
```

At this point setup is complete and metrics data is being sent to Sumo Logic.

#### Missing metrics for `controller-manager` or `scheduler`

Since there is a backward compatibility issue in the current version of chart, you may need to follow a workaround for sending these metrics under `controller-manager` or `scheduler`:

```sh
kubectl -n kube-system patch service prometheus-operator-kube-controller-manager -p '{"spec":{"selector":{"k8s-app": "kube-controller-manager"}}}'
kubectl -n kube-system patch service prometheus-operator-kube-scheduler -p '{"spec":{"selector":{"k8s-app": "kube-scheduler"}}}'
kubectl -n kube-system patch service prometheus-operator-kube-controller-manager --type=json -p='[{"op": "remove", "path": "/spec/selector/component"}]'
kubectl -n kube-system patch service prometheus-operator-kube-scheduler --type=json -p='[{"op": "remove", "path": "/spec/selector/component"}]'
```

#### Additional configuration options

#### Metrics

##### Filter metrics

The `prometheus-overrides.yaml` file specifies metrics to be collected. If you want to exclude some metrics from collection, or include others, you can edit `prometheus-overrides.yaml`. The file contains a section like the following for each of the Kubernetes components that report metrics in this solution: API server, Controller Manager, and so on.

If you would like to collect other metrics that are not listed in `prometheus-overrides.yaml`, you can add a new section to the file.

```yaml
    - url: http://fluentd:9888/prometheus.metrics.<some_label>
      writeRelabelConfigs:
      - action: keep
        regex: <metric1>|<metric2>|...
        sourceLabels: [__name__]
```

The syntax of `writeRelabelConfigs` can be found [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write).
You can supply any label you like. You can query Prometheus to see a complete list of metrics it’s scraping.

##### Trim and relabel metrics

You can specify relabeling, and additional inclusion or exclusion options in `fluentd-sumologic.yaml`.

The options you can use are described [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/master/fluent-plugin-prometheus-format).

Make your edits in the `<filter>` stanza in the ConfigMap section of `fluentd-sumologic.yaml`.

```xml
<filter prometheus.datapoint**>
  @type prometheus_format
  relabel container_name:container,pod_name:pod
</filter>
```

Sumo is using `relabel` parameter to standardize the metadata fields (`container_name` -> `container`,`pod_name` -> `pod`).
You can use `inclusion` or `exclusion` configuration options to further filter metrics by labels. For example:

```xml
<filter prometheus.datapoint**>
  @type prometheus_format
  relabel service,container_name:container,pod_name:pod
  inclusions { "namespace" : "kube-system" }
</filter>
```

This filter will:

* Trim the service metadata from the metric datapoint.
* Rename the label/metadata `container_name` to `container`, and `pod_name` to `pod`.
* Only apply to metrics with the `kube-system` namespace

#### Custom Metrics

If you have custom metrics you'd like to send to Sumo via Prometheus, you just need to expose a `/metrics` endpoint in prometheus format, and instruct prometheus via a ServiceMonitor to pull data from the endpoint. In this section, we'll walk through collecting custom metrics with Prometheus.

##### Step 1: Expose a `/metrics` endpoint on your service

There are many pre-built libraries that the community has built to expose these, but really any output that aligns with the prometheus format can work. Here is a list of libraries: [Libraries](https://prometheus.io/docs/instrumenting/clientlibs). Manually verify that you have metrics exposed in Prometheus format by hitting the metrics endpoint, and verifying that the output follows the [Prometheus format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md).

##### Step 2: Set up a service monitor so that Prometheus pulls the data

Service Monitors is how we tell Prometheus what endpoints and sources to pull metrics from. To define a Service Monitor, create a yaml file on disk with information templated as follows:

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  labels:
    team: frontend
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - port: web
  ```

Replace the `name` with a name that relates to your service, and a `matchLabels` that would match the pods you want this service monitor to scrape against. By default, prometheus attempts to scrape metrics off of the `/metrics` endpoint, but if you do need to use a different url, you can override it by providing a `path` attribute in the settings like so:

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: prometheus-operator-kubelet
  name: prometheus-operator-kubelet
  namespace: sumologic
  release: prometheus-operator
spec:
  endpoints:
  - path: /metrics/cadvisor
    port: https-metrics
...
```

Note, you need to ensure the `release` label matches the `release` label on your Prometheus pod.

Detailed instructions on service monitors can be found via [Prometheus-Operator](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md#related-resources) website.
Once you have created this yaml file, go ahead and run `kubectl create -f name_of_yaml.yaml -n sumologic`. This will create the service monitor in the sumologic namespace.

##### Step 3: Create a new HTTP source in Sumo Logic.

To avoid [blacklisting](https://help.sumologic.com/Metrics/Understand_and_Manage_Metric_Volume/Blacklisted_Metrics_Sources) metrics should be distributed across multiple HTTP sources. You can [follow these steps](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) to create a new HTTP source for your custom metrics. Make note of the URL as you will need it in the next step.

##### Step 4: Update the metrics.conf FluentD Configuration

Next, you will need to update the Fluentd configuration to ensure Fluentd routes your custom metrics to the HTTP source you created in the previous step.

  * First, base64 encode the HTTP source URL from the previous step by running `echo <HTTP_SOURCE_URL> | base64`.  Replace `<HTTP_SOURCE_URL>` with the URL from step 3.
  * Next, you can edit the secret that houses all the HTTP sources URLs. Assuming you installed the collector in the  `sumologic` namespace, you can run `kubectl -n sumologic edit secret sumologic` or edit the YAML you deployed when you set up collection.
  * In the `data` section, add a new key and the base64 encoded value you created. The following is just a snippet of the secret for an example. Do not alter the existing content, you simply want to add a new key.
  
```yaml
data:
...
my-custom-metrics: <base64EncodedURL>
kind: Secret
```

  * Next you need to edit the FluentD Deployment and add a new environment variable, pointing to the new secret.  Assuming you installed the collector in the  `sumologic` namespace, you can run `kubectl -n sumologic edit deployment fluentd` or edit the YAML you deployed when you set up collection. Note, if you installed using helm, the name of the deployment may be different depending on how you installed the helm chart.
  * Locate the `SUMO_ENDPOINT_LOGS` environment variable in the YAML and add a new environment variable that points to the secret key you created. The following is an example.
  
```yaml
...
        - name: SUMO_ENDPOINT_LOGS
          valueFrom:
            secretKeyRef:
              key: endpoint-logs
              name: sumologic
        - name: MY_CUSTOM_METRICS
          valueFrom:
            secretKeyRef:
              key: my-custom-metrics
              name: sumologic
        - name: LOG_FORMAT
          value: fields
```

  * Finally, you need to modify the Fluentd config to route data to your newly created HTTP source. Assuming you installed the collector in the `sumologic` namespace, you can run `kubectl -n sumologic edit configmap fluentd` or edit the YAML you deployed when you set up collection. Note, if you installed using helm, the name of the deployment may be different depending on how you installed the helm chart.
  * Locate the section `match prometheus.metrics` and you will insert a new section above this. The `match` statement should end with a tag that identifies your data that FluentD will use for routing. Then make sure you point to the environment variable you added to your deployment. The following is an example.
  
```yaml
...        
          <match prometheus.metrics.YOUR_TAG>
             @type sumologic
             @id sumologic.endpoint.metrics
             endpoint "#{ENV['MY_CUSTOM_METRICS']}"
             @include metrics.output.conf
           </match>
          <match prometheus.metrics**>
             @type sumologic
             @id sumologic.endpoint.metrics
             endpoint "#{ENV['SUMO_ENDPOINT_METRICS']}"
             @include metrics.output.conf
           </match>
```

##### Step 5: Update the prometheus-overrides.yaml file to forward the metrics to FluentD.

The `prometheus-overrides.yaml` file controls what metrics get forwarded on to Sumo Logic. To send custom metrics to Sumo Logic you need to update the `prometheus-overrides.yaml` file to include a rule to forward on your custom metrics. Make sure you include the same tag you created in your FluentD configmap in the previous step. Here is an example addition to the `prometheus-overrides.yaml` file that will forward metrics to Sumo:

```
- url: http://collection-sumologic.sumologic.svc.cluster.local:9888/prometheus.metrics.YOUR_TAG
      writeRelabelConfigs:
      - action: keep
        regex: <YOUR_CUSTOM_MATCHER>
        sourceLabels: [__name__]
```

Replace `YOUR_TAG` with a tag to identify these metrics. After adding this to the `yaml`, go ahead and run a `helm upgrade prometheus-operator stable/prometheus-operator -f prometheus-overrides.yaml` to upgrade your `prometheus-operator`.

Note: When executing the helm upgrade, to avoid the error below, you need to add the argument `--force`.

      invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/name":"kube-state-metrics"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable

If all goes well, you should now have your custom metrics piping into Sumo Logic.

### Step 3: Deploy FluentBit

In this step, you will deploy FluentBit to forward logs to Fluentd.

Run the following commands to download the FluentBit fluent-bit-overrides.yaml file and install `fluent-bit`

```bash
$ cd /path/to/helm/charts/
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.6.0/deploy/helm/fluent-bit-overrides.yaml
$ helm template stable/fluent-bit --name fluent-bit --set dryRun=true -f fluent-bit-overrides.yaml > fluent-bit.yaml
$ kubectl apply -f fluent-bit.yaml
```

### Step 4: Deploy Falco

In this step, you will deploy [Falco](https://falco.org/) to detect anomalous activity and capture Kubernetes Audit Events. This step is required only if you intend to use the Sumo Logic Kubernetes App.

Download the file `falco-overrides.yaml` from GitHub:

```bash
$ cd /path/to/helm/charts/
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.6.0/deploy/helm/falco-overrides.yaml
```

__NOTE__ `Google Kubernetes Engine (GKE)` uses Container-Optimized OS (COS) as the default operating system for its worker node pools. COS is a security-enhanced operating system that limits access to certain parts of the underlying OS. Because of this security constraint, Falco cannot insert its kernel module to process events for system calls. However, COS provides the ability to leverage eBPF (extended Berkeley Packet Filter) to supply the stream of system calls to the Falco engine. eBPF is currently supported only on GKE and COS. More details [here](https://falco.org/docs/installation/).

To install `Falco` on `GKE`, uncomment the following lines in the file `falco-overrides.yaml`:

```
ebpf:
  enabled: true
```

Install `falco` by generating the yaml files using Helm:

```bash
$ helm template stable/falco --name falco --set dryRun=true -f falco-overrides.yaml > falco.yaml
$ kubectl apply -f falco.yaml
```

## Tear down

To delete `falco` from the Kubernetes cluster:

```sh
helm del --purge falco
```

To delete `fluent-bit` from the Kubernetes cluster:

```sh
helm del --purge fluent-bit
```

To delete `prometheus-operator` from the Kubernetes cluster:

```sh
helm del --purge prometheus-operator
```

__NOTE__ This command will not remove the Custom Resource Definitions created.

To delete the `fluentd-sumologic` app:

```sh
kubectl delete -f ./fluentd-sumologic.yaml
```

To delete the `sumologic` secret (for recreating collector/sources):

```sh
kubectl -n sumologic delete secret sumologic
```

To delete the `sumologic` namespace and all resources under it:

```sh
kubectl delete namespace sumologic
```

## Adding Additional FluentD Plugins
To add additional FluentD plugins, you can simply create a new Docker image from our provided Docker image.
 
__Note__: You will want to update `<RELEASE>` to the [docker tag](https://hub.docker.com/r/sumologic/kubernetes-fluentd/tags) you wish to use.

```
FROM sumologic/kubernetes-fluentd:<RELEASE>

USER root
RUN gem install fluent-plugin-aws-elasticsearch-service

USER fluent
```

# Troubleshooting Collection

## Namespace configuration

The following `kubectl` commands assume you are in the correct namespace `sumologic`. By default, these commands will use the namespace `default`.

To run a single command in the `sumologic` namespace, pass in the flag `-n sumologic`.

To set your namespace context more permanently, you can run
```sh
kubectl config set-context $(kubectl config current-context) --namespace=sumologic
```

## Gathering logs

First check if your pods are in a healthy state. Run
```
kubectl get pods
```
to get a list of running pods. If any of them are not in the `Status: running` state, something is wrong. To get the logs for that pod, you can either:

Stream the logs to `stdout`:
```
kubectl logs POD_NAME -f
```
Or write the current logs to a file:
```
kubectl logs POD_NAME > pod_name.log
```

To get a snapshot of the current state of the pod, you can run
```
kubectl describe pods POD_NAME
```

### Fluentd Logs

```
kubectl logs fluentd-xxxxxxxxx-xxxxx -f
```

To enable more detailed debug or trace logs from all of Fluentd, add the following lines to the `fluentd-sumologic.yaml` file under the relevant `.conf` section and apply the change to your deployment:
```
<system>
  log_level debug # or trace
</system>
```

To enable debug or trace logs from a specific Fluentd plugin, add the following option to the plugin's `.conf` section:
```
<match **>
  @type sumologic
  @log_level debug # or trace
  ...
</match>
```

### Prometheus Logs

To view Prometheus logs:
```
kubectl logs prometheus-prometheus-operator-prometheus-0 prometheus -f
```

### Send data to Fluentd stdout instead of to Sumo

To help reduce the points of possible failure, we can write data to Fluentd logs rather than sending to Sumo directly using the Sumo Logic output plugin. To do this, change the following lines in the `fluentd-sumologic.yaml` file under the relevant `.conf` section:

```
<match TAG_YOU_ARE_DEBUGGING>
  @type sumologic
  endpoint "#{ENV['SUMO_ENDPOINT']}"
  ...
</match>
```

to

```
<match TAG_YOU_ARE_DEBUGGING>
  @type stdout
</match>
```

Then redeploy your `fluentd` deployment:

```sh
kubectl delete deployment fluentd
kubectl apply -f /path/to/fluentd-sumologic.yaml
```

You should see data being sent to Fluentd logs, which you can get using the commands [above](#fluentd-logs).

## Gathering metrics

### Check the `/metrics` endpoint

You can `port-forward` to a pod exposing `/metrics` endpoint and verify it is exposing Prometheus metrics:

```sh
kubectl port-forward fluentd-6f797b49b5-52h82 8080:24231
```

Then, in your browser, go to `localhost:8080/metrics`. You should see Prometheus metrics exposed.

### Check the Prometheus UI

First run the following command to expose the Prometheus UI:

```sh
kubectl port-forward prometheus-prometheus-operator-prometheus-0 8080:9090
```

Then, in your browser, go to `localhost:8080`. You should be in the Prometheus UI now.

From here you can start typing the expected name of a metric to see if Prometheus auto-completes the entry.

If you can't find the expected metrics, you can check if Prometheus is successfully scraping the `/metrics` endpoints. In the top menu, navigate to section `Status > Targets`. Check if any targets are down or have errors.

### Check Prometheus Remote Storage

We rely on the Prometheus [Remote Storage](https://prometheus.io/docs/prometheus/latest/storage/) integration to send metrics from Prometheus to the FluentD collection pipeline.

You can follow [Deploy Fluentd](#prometheus-logs) to verify there are no errors during remote write.

You can also check `prometheus_remote_storage_.*` metrics to look for success/failure attempts.

### Check FluentBit and FluentD output metrics

By default, we collect input/output plugin metrics for FluentBit, and output metrics for FluentD that you can use to verify collection:

Relevant FluentBit metrics include:

- fluentbit_input_bytes_total
- fluentbit_input_records_total
- fluentbit_output_proc_bytes_total
- fluentbit_output_proc_records_total
- fluentbit_output_retries_total
- fluentbit_output_retries_failed_total

Relevant FluentD metrics include:

- fluentd_output_status_emit_records
- fluentd_output_status_buffer_queue_length
- fluentd_output_status_buffervqueuevbytes
- fluentd_output_status_num_errors
- fluentd_output_status_retry_count

## Common Issues

### Pod stuck in `ContainerCreating` state

If you are seeing a pod stuck in the `ContainerCreating` state and seeing logs like
```
Warning  FailedCreatePodSandBox  29s   kubelet, ip-172-20-87-45.us-west-1.compute.internal  Failed create pod sandbox: rpc error: code = DeadlineExceeded desc = context deadline exceeded
```
you have an unhealthy node. Killing the node should resolve this issue.

### Missing `kubelet` metrics

Navigate to the `kubelet` targets using the steps above. You may see that the targets are down with 401 errors. If so, there are two known workarounds you can try.

#### 1. Enable the `authenticationTokenWebhook` flag in the cluster

The goal is to set the flag `--authentication-token-webhook=true` for `kubelet`. One way to do this is:
```
kops get cluster -o yaml > NAME_OF_CLUSTER-cluster.yaml
```

Then in that file make the following change:
```
spec:
  kubelet:
    anonymousAuth: false
    authenticationTokenWebhook: true # <- add this line
```

Then run
```
kops replace -f NAME_OF_CLUSTER-cluster.yaml
kops update cluster --yes
kops rolling-update cluster --yes
```

#### 2. Disable the `kubelet.serviceMonitor.https` flag in the Prometheus operator

The goal is to set the flag `kubelet.serviceMonitor.https=false` when deploying the prometheus operator.

Add the following lines to the beginning of your `prometheus-overrides.yaml` file:
```
kubelet:
  serviceMonitor:
    https: false
```

and redeploy Prometheus:
```
helm del --purge prometheus-operator
helm install stable/prometheus-operator --name prometheus-operator --namespace sumologic -f prometheus-overrides.yaml
```

### Missing `kube-controller-manager` or `kube-scheduler` metrics

There’s an issue with backwards compatibility in the current version of the prometheus-operator helm chart that requires us to override the selectors for kube-scheduler and kube-controller-manager in order to see metrics from them. If you are not seeing metrics from these two targets, try running the commands in the "Configure Prometheus" section [above](#missing-metrics-for-controller-manager-or-scheduler).

### Rancher

If you are running the out of the box rancher monitoring setup, you cannot run our Prometheus operator alongside it. The Rancher Prometheus Operator setup will actually kill and permanently terminate our Prometheus Operator instance and will prevent the metrics system from coming up.
If you have the Rancher prometheus operator setup running, they will have to use the UI to disable it before they can install our collection process.

