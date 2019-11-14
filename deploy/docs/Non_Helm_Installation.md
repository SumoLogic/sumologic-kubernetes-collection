# Non Helm Installation

This document has instructions for setting up collection with FluentD, FluentBit, and Prometheus.

<!-- TOC -->

- [Before you start](#before-you-start) 
- [Create Sumo Fields, a collector, and deploy Fluentd](#create-sumo-fields-a-collector-and-deploy-fluentd) 
  - [Automatic Source Creation and Setup Script](#automatic-source-creation-and-setup-script) 
    - [Parameters](#parameters) 
    - [Environment variables](#environment-variables) 
  - [Manual Source Creation and Setup](#manual-source-creation-and-setup) 
    - [Create a Hosted Collector and an HTTP Source](#create-a-hosted-collector-and-an-http-source) 
    - [Deploy Fluentd](#deploy-fluentd) 
      - [Use default configuration](#use-default-configuration) 
      - [Customize configuration](#customize-configuration) 
  - [Verify the pods are running](#verify-the-pods-are-running) 
- [Configure Prometheus](#configure-prometheus) 
  - [Missing metrics for `controller-manager` or `scheduler`](#missing-metrics-for-controller-manager-or-scheduler) 
- [Deploy FluentBit](#deploy-fluentbit) 
- [Deploy Falco](#deploy-falco)
- [Tear down](#tear-down) 

<!-- /TOC -->

## Before you start

* If you haven’t already done so, create your Kubernetes cluster. Verify that you can access the cluster with `kubectl`.
* Verify that the cluster DNS service is enabled. For more information, see [DNS](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/#dns) in Kubernetes documentation.
* Verify that you are in the correct context. You can check your current context and set your desired context with:
```
kubectl config current-context
kubectl config use-context DESIRED_CONTEXT_NAME
```
* In the Non-Helm installation steps, you will never need to run `helm install`, but we use Helm as a templating tool to generate the yaml files to install various components of our solution. Thus you will still need to install Helm:

*Note the following steps are one way to install Helm, but in order to ensure property security, please be sure to review the [Helm documentation.](https://helm.sh/docs/using_helm/#securing-your-helm-installation)*

Download Helm to generate the yaml files necessary to deploy by running

```bash
brew install kubernetes-helm
```

__NOTE__ These instructions assume that Prometheus is not already running on your Kubernetes cluster.

## Create Sumo Fields, a Collector, and deploy Fluentd

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

### Automatic Source Creation and Setup Script

This approach requires access to the Sumo Logic Collector API. It will create a Hosted Collector and multiple HTTP Source endpoints and pre-populate Kubernetes secrets detailed in the manual steps below.

```sh
curl -s https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/docker/setup/setup.sh \
  | bash -s - [-c <collector_name>] [-k <cluster_name>] [-n <namespace>] [-a <boolean>] [-d <boolean>] [-y <boolean>] <api_endpoint> <access_id> <access_key>
```

__NOTE__ This script will be executed in bash and requires [jq command-line JSON parser](https://stedolan.github.io/jq/download/) to be installed.

#### Parameters

* __-c &lt;collector_name&gt;__ - optional. Name of Sumo Collector that will be created. If not specified, it will be named as `kubernetes-<timestamp>`
* __-k &lt;cluster_name&gt;__ - optional. Name of the Kubernetes cluster that will be attached to logs and events as metadata. If not specified, it will be named as `kubernetes-<timestamp>`. For metrics, specify the cluster name in the `prometheus-overrides.yaml` provided for the prometheus operator; further details in [step 2](#step-2-configure-prometheus).
* __-n &lt;namespace&gt;__ - optional. Name of the Kubernetes namespace in which to deploy resources. If not specified, the namespace will default to `sumologic`.
* __-a &lt;boolean&gt;__ - optional. Set this to true if you want to deploy with the latest alpha version. If not specified, the latest release will be deployed.
* __-d &lt;boolean&gt;__ - optional. Set this to false to only set up the Sumo Collector and Sources and download the YAML file, but not to deploy so you can customize the YAML file, such as configuring fields for [events](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/fluent-plugin-events/README.md#fluent-plugin-events). If not specified, the default configuration will deploy.
* __-y &lt;boolean&gt;__ - optional. When -d is set to false you can also set this to false to not download the YAML file. If not specified, the YAML file will be downloaded.
* __&lt;api_endpoint&gt;__ - required. See [API endpoints](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security) for details.
* __&lt;access_id&gt;__ - required. Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __&lt;access_key&gt;__ - required. Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

#### Environment variables
The parameters for Collector name, cluster name and namespace may also be passed in via environment variables instead of script arguments. If the script argument is supplied that trumps the environment variable.
* __SUMO_COLLECTOR_NAME__ - optional. Name of Sumo Collector that will be created. If not specified, it will be named as `kubernetes-<timestamp>`
* __KUBERNETES_CLUSTER_NAME__ - optional. Name of the Kubernetes cluster that will be attached to logs and events as metadata. If not specified, it will be named as `kubernetes-<timestamp>`. For metrics, specify the cluster name in the `prometheus-overrides.yaml` provided for the prometheus operator; further details in [step 2](#step-2-configure-prometheus).
* __SUMO_NAMESPACE__ - optional. Name of the Kubernetes namespace in which to deploy resources. If not specified, the namespace__ will default to `sumologic`

__Note:__ The script will generate a YAML file (`fluentd-sumologic.yaml`) with all the deployed Kuberentes resources on disk. Save this file for easy teardown and redeploy of the resources.

Next, you will set up [Prometheus](#configure-prometheus).

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

Next, you will set up [Prometheus](#configure-prometheus).

## Configure Prometheus

In this step, you will configure the Prometheus server to write metrics to Fluentd.

First, you will need to fetch the `prometheus-operator` helm chart.

```bash
$ helm fetch --repo https://kubernetes-charts.storage.googleapis.com/ --untar --untardir ./charts --version 6.2.1 prometheus-operator
```

__NOTE__ This will download a local copy of the chart to the working directory.  The following commands assume you are in the same working directory.

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

Download the Prometheus Operator `prometheus-overrides.yaml` by running

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.11.0/deploy/helm/prometheus-overrides.yaml
```

Before installing `prometheus-operator`, edit `prometheus-overrides.yaml` to define a unique cluster identifier. The default value of the `cluster` field in the `externalLabels` section of `prometheus-overrides.yaml` is `kubernetes`. If you will be deploying the metric collection solution on multiple Kubernetes clusters, you will want to use a unique identifier for each. For example, you might use “Dev”, “Prod”, and so on.

__NOTE__ It’s fine to change the value of the `cluster` field, but don’t change the field name (key).

__NOTE__ If you plan to install Prometheus in a different namespace than you deployed Fluentd to in Step 1, or you have an existing Prometheus you plan to apply our configuration to running in a different namespace,  please update the remote write API configuration to use the full service URL like, `http://collection-sumologic.sumologic.svc.cluster.local:9888`.

You can also [Filter metrics](additional_prometheus_configuration.md#filter-metrics) and [Trim and relabel metrics](additional_prometheus_configuration.md#trim-and-relabel-metrics) in `prometheus-overrides.yaml`.

Install `prometheus-operator` by generating the yaml files using Helm:

```bash
<<<<<<< HEAD
$ helm fetch stable/prometheus-operator --version 6.2.1
$ helm template prometheus-operator-6.2.1.tgz --name prometheus-operator --namespace=sumologic -f prometheus-overrides.yaml > prometheus.yaml
```

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

=======
$ helm template ./charts/prometheus-operator --name prometheus-operator --namespace=sumologic -f prometheus-overrides.yaml > prometheus.yaml
```
>>>>>>> ef4063a5821842134096b5ea2a40559e6611c267
Before applying, change your default namespace for `kubectl` from `default` to `sumologic`. This is required as the YAML generated will deploy some resources to `kube-system` namespace as well.

```bash
$ kubectl config set-context --current --namespace=sumlogic
$ kubectl apply -f prometheus.yaml
```

Verify `prometheus-operator` is running:

```sh
kubectl -n sumologic logs prometheus-prometheus-operator-prometheus-0 prometheus -f
```

At this point setup is complete and metrics data is being sent to Sumo Logic.

<<<<<<< HEAD
__NOTE__ You can also [send custom metrics](additional_prometheus_configuration.md#custom-metrics)to Sumo Logic from Prometheus.
=======
__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)
>>>>>>> ef4063a5821842134096b5ea2a40559e6611c267

### Missing metrics for `controller-manager` or `scheduler`

Since there is a backward compatibility issue in the current version of chart, you may need to follow a workaround for sending these metrics under `controller-manager` or `scheduler`:

```sh
kubectl -n kube-system patch service prometheus-operator-kube-controller-manager -p '{"spec":{"selector":{"k8s-app": "kube-controller-manager"}}}'
kubectl -n kube-system patch service prometheus-operator-kube-scheduler -p '{"spec":{"selector":{"k8s-app": "kube-scheduler"}}}'
kubectl -n kube-system patch service prometheus-operator-kube-controller-manager --type=json -p='[{"op": "remove", "path": "/spec/selector/component"}]'
kubectl -n kube-system patch service prometheus-operator-kube-scheduler --type=json -p='[{"op": "remove", "path": "/spec/selector/component"}]'
```


## Deploy FluentBit

In this step, you will deploy FluentBit to forward logs to Fluentd.

<<<<<<< HEAD
Run the following commands to download the FluentBit `fluent-bit-overrides.yaml` file and install `fluent-bit`

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.11.0/deploy/helm/fluent-bit-overrides.yaml
$ helm fetch stable/fluent-bit --version 2.4.4
$ helm template fluent-bit-2.4.4.tgz --name fluent-bit --namespace=sumologic -f fluent-bit-overrides.yaml > fluent-bit.yaml
$ kubectl apply -f fluent-bit.yaml
```

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

## Deploy Falco

In this step, you will deploy [Falco](https://falco.org/) to detect anomalous activity and capture Kubernetes Audit Events. This step is required only if you intend to use the Sumo Logic Kubernetes App.

Download the file `falco-overrides.yaml` from GitHub:

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.11.0/deploy/helm/falco-overrides.yaml
$ helm fetch stable/falco --version 1.0.8
$ helm template falco-1.0.8.tgz --name falco --namespace=sumologic -f falco-overrides.yaml > falco.yaml
$ kubectl apply -f falco.yaml
```

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

=======
First, you will need to fetch the `fluent-bit` helm chart.

```bash
$ helm fetch --repo https://kubernetes-charts.storage.googleapis.com/ --untar --untardir ./charts --version 2.4.4 fluent-bit
```

__NOTE__ This will download a local copy of the chart to the working directory.  The following commands assume you are in the same working directory.

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

Download the Prometheus Operator `fluent-bit-overrides.yaml` by running

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.11.0/deploy/helm/fluent-bit-overrides.yaml
```

Install `fluent-bit` by generating the yaml files using Helm:

```bash
$ helm template ./charts/fluent-bit --name fluent-bit --namespace=sumologic -f fluent-bit-overrides.yaml > fluent-bit.yaml
$ kubectl apply -f fluent-bit.yaml
```

## Deploy Falco

In this step, you will deploy [Falco](https://falco.org/) to detect anomalous activity and capture Kubernetes Audit Events. This step is required only if you intend to use the Sumo Logic Kubernetes App.

First, you will need to fetch the `falco` helm chart.

```bash
$ helm fetch --repo https://kubernetes-charts.storage.googleapis.com/ --untar --untardir ./charts --version 1.0.8 falco
```

__NOTE__ This will download a local copy of the chart to the working directory.  The following commands assume you are in the same working directory.

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

Download the Prometheus Operator `falco-overrides.yaml` by running

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.11.0/deploy/helm/falco-overrides.yaml
```

Install `falco` by generating the yaml files using Helm:

```bash
$ helm template ./charts/falco --name falco --namespace=sumologic -f falco-overrides.yaml > falco.yaml
$ kubectl apply -f falco.yaml
```
>>>>>>> ef4063a5821842134096b5ea2a40559e6611c267
__NOTE__ `Google Kubernetes Engine (GKE)` uses Container-Optimized OS (COS) as the default operating system for its worker node pools. COS is a security-enhanced operating system that limits access to certain parts of the underlying OS. Because of this security constraint, Falco cannot insert its kernel module to process events for system calls. However, COS provides the ability to leverage eBPF (extended Berkeley Packet Filter) to supply the stream of system calls to the Falco engine. eBPF is currently supported only on GKE and COS. More details [here](https://falco.org/docs/installation/).

To install `Falco` on `GKE`, uncomment the following lines in the file `falco-overrides.yaml`:

```
ebpf:
  enabled: true
```

Install `falco` by generating the yaml files using Helm:

```bash
$ helm template ./charts/falco --name falco --set dryRun=true -f falco-overrides.yaml > falco.yaml
$ kubectl apply -f falco.yaml
```


## Tear down

To delete `falco` from the Kubernetes cluster:

```sh
kubectl delete -f falco.yaml
```

To delete `fluent-bit` from the Kubernetes cluster:

```sh
kubectl delete -f fluent-bit.yaml
```

To delete `prometheus-operator` from the Kubernetes cluster:

```sh
kubectl delete -f prometheus.yaml
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
