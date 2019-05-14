# Deployment Guide

This page has instructions for collecting Kubernetes metrics; enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic.

__NOTE__ This page describes preview software. If you have comments or issues, please add an issue [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/issues).

## Table of Contents

### [Deployment Guide](#deployment-guide)

* [Solution Overview](#solution-overview)
* [Before you start](#before-you-start)
* [Step 1: Create Sumo collector and deploy Fluentd](#step-1-create-sumo-collector-and-deploy-fluentd)
  * [Automatic with setup script](#automatic-with-setup-script)
  * [Manual](#manual)
* [Step 2: Configure Prometheus](#step-2-configure-prometheus)
* [Filter metrics](#filter-metrics)
* [Trim and relabel metrics](#trim-and-relabel-metrics)
* [Tear down](#tear-down)

### [Debugging the Kubernetes Collection Pipeline](#debugging-the-kubernetes-collection-pipeline-1)

* [General steps for debugging issues](#general-steps-for-debugging-issues)
  * [1. Use `kubectl` to get logs and state](#1-use-kubectl-to-get-logs-and-state)
  * [2. Send data to Fluentd stdout instead of to Sumo](#2-send-data-to-fluentd-stdout-instead-of-to-sumo)
  * [3. [Metrics] Check the Prometheus UI](#3-metrics-check-the-prometheus-ui)
* [Missing `kubelet` metrics](#missing-kubelet-metrics)
  * [1. Enable the `authenticationTokenWebhook` flag in the cluster](#1-enable-the-authenticationtokenwebhook-flag-in-the-cluster)
  * [2. Disable the `kubelet.serviceMonitor.https` flag in the Prometheus operator](#2-disable-the-kubeletservicemonitorhttps-flag-in-the-prometheus-operator)
* [Missing `kube-controller-manager` or `kube-scheduler` metrics](#missing-kube-controller-manager-or-kube-scheduler-metrics)

## Solution overview

The diagram below illustrates the components of the Kubernetes metric collection solution.

![solution](/images/k8s-metrics3.png)

* **K8S API Server**. Exposes API server metrics.
* **Scheduler.** Makes Scheduler metrics available on an HTTP metrics port.
* **Controller Manager.** Makes Controller Manager metrics available on an HTTP metrics port.
* **node-exporter.** The `node_exporter` add-on exposes node metrics, including CPU, memory, disk, and network utilization.
* **kube-state-metrics.** Listens to the Kubernetes API server; generates metrics about the state of the deployments, nodes and pods in the cluster; and exports the metrics as plaintext on an HTTP endpoint listen port.
* **Prometheus deployment.** Scrapes the metrics exposed by the `node-exporter` add-on for Kubernetes and the `kube-state-metric`s component; writes metrics to a port on the Fluentd deployment.
* **Fluentd deployment.** Forwards metrics to HTTP sources on a hosted collector. Includes multiple Fluentd plugins that parse and format the metrics and enrich them with metadata.

## Before you start

* If you haven’t already done so, create your Kubernetes cluster. Verify that you can access the cluster with `kubectl`.
* Verify that the cluster DNS service is enabled. For more information, see [DNS](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/#dns) in Kubernetes documentation.

__NOTE__ These instructions assume that Prometheus is not already running on your Kubernetes cluster.

## Step 1: Create Sumo collector and deploy Fluentd

In this step you create a Sumo Logic hosted collector with a set of HTTP sources to receive your Kubernetes metrics; creates Kubernetes secrets for the HTTP sources created; and deploy Fluentd using a Sumo-provided .yaml manifest.

### Automatic with setup script

This approach requires the access to Sumo Logic Collector API.

```sh
curl -s https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/setup.sh \
  | bash -s <api-endpoint> <access-id> <access-key> [collector-name]
```

__NOTE__ This script will be executed in bash and require [jq command-line JSON parser](https://stedolan.github.io/jq/download/) installed.

#### Parameters

* __api-endpoint__ - required. The API endpoint from [this page](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security).
* __access-id__ - required. Sumo [access id](https://help.sumologic.com/Manage/Security/Access-Keys)
* __access-key__ - required. Sumo [access key](https://help.sumologic.com/Manage/Security/Access-Keys)
* __collector-name__ - optional. Name of Sumo collector will be created. If not specified, will be named as `kubernetes-<timestamp>`

### Manual

This is a manual alternative approach for the automatic script if you don't have API access or need customized configuration (like using an exist collector).

#### 1.1 Create a hosted collector and an HTTP source

In this step you create a Sumo Logic hosted collector with a set of HTTP sources to receive your Kubernetes metrics.

Create a hosted collector, following the instructions on [Configure a Hosted Collector](https://help.sumologic.com/03Send-Data/Hosted-Collectors/Configure-a-Hosted-Collector) in Sumo help. (If you already have a Sumo hosted collector that you want to use, skip this step.)

Create seven HTTP sources on the collector you created in the previous step, one for each of the Kubernetes components that report metrics in this solution:

* api-server
* kubelet
* controller-manager
* scheduler
* kube-state-metrics
* node-exporter
* default

Follow the instructions on [HTTP Logs and Metrics Source](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in Sumo help, with the following additions:

* **Naming the sources.** You can assign any name you like to the sources, but it’s a good idea to assign a name to each source that reflects the Kubernetes component from which it receives metrics. For example, you might name the source that receives API Server metrics “api-server”.
* **HTTP Source URLs.** When you configure each HTTP source, Sumo will display the URL of the HTTP endpoint. Make a note of the URL. You will use it when you configure the Kubernetes service to send data to Sumo.

#### 1.2 Deploy Fluentd

In this step you deploy Fluentd using a Sumo-provided .yaml manifest. This step also creates Kubernetes secrets for the HTTP sources created in the previous step.

Run following command to create namespace `sumologic`

```sh
kubectl create namespace sumologic
```

Run following command to create Kubernetes secrets contains 7 HTTP source URLs just created.

```sh
kubectl -n sumologic create secret generic metric-endpoints \
  --from-literal=endpoint-metrics=$ENDPOINT_METRICS \
  --from-literal=endpoint-metrics-apiserver=$ENDPOINT_METRICS_APISERVER \
  --from-literal=endpoint-metrics-kube-controller-manager=$ENDPOINT_METRICS_KUBE_CONTROLLER_MANAGER \
  --from-literal=endpoint-metrics-kube-scheduler=$ENDPOINT_METRICS_KUBE_SCHEDULER \
  --from-literal=endpoint-metrics-kube-state=$ENDPOINT_METRICS_KUBE_STATE \
  --from-literal=endpoint-metrics-kubelet=$ENDPOINT_METRICS_KUBELET \
  --from-literal=endpoint-metrics-node-exporter=$ENDPOINT_METRICS_NODE_EXPORTER
```

Apply `fluentd-sumologic.yaml` manifest with following command:

```sh
kubectl apply -f https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/fluentd-sumologic.yaml
```

The manifest will create the Kubernetes resources required by Fluentd.

### Verify the pod(s) are running

```sh
kubectl -n sumologic get pod
```

## Step 2: Configure Prometheus

In this step, you configure the Prometheus server to write metrics to Fluentd.

Install Helm:

```sh
brew install kubernetes-helm
```

Apply `tiller-rbac.yaml` manifest with `kubectl`, and deploy Tiller with a service account:

```sh
kubectl apply -f https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/tiller-rbac.yaml \
  && helm init --service-account tiller
```

This manifest binds the default `cluster-admin` ClusterRole in your Kubernetes cluster to the `tiller` service account (which is created when you deploy Tiller in the following step.)

Download the Prometheus Operator `overrides.yaml` from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/overrides.yaml
```

Before installing `prometheus-operator`, edit `overrides.yaml` to define a unique cluster identifier. The default value of the `cluster` field in the `externalLabels` section of `overrides.yaml` is `kubernetes`. Assuming you’ll deploying the metric collection solution to multiple Kubernetes clusters, you want to have a unique identifier for each. For example, you might use “Dev”, “Prod”, and so on.

__NOTE__ It’s fine to change the value of the `cluster` field, but don’t change the field name (key).

You can also [Filter metrics](#filter-metrics) and [Trim and relabel metrics](#trim-and-relabel-metrics) in `overrides.yaml`.

Install `prometheus-operator` using Helm:

```sh
helm repo update \
   && helm install stable/prometheus-operator --name prometheus-operator --namespace sumologic -f overrides.yaml
```

__NOTE__ If Custom Resource Definitions (CRD) were created earlier, add `--no-crd-hook` to the end of the command.

Verify `prometheus-operator` is running:

```sh
kubectl -n sumologic logs prometheus-prometheus-operator-prometheus-0 prometheus -f
```

#### Missing metrics for `controller-manager` or `scheduler`

Since there is a backward compatible issue in the current version of chart, you may need following workaround for sending the metrics under `controller-manager` or `scheduler`:

```sh
kubectl -n kube-system patch service prometheus-operator-kube-controller-manager -p '{"spec":{"selector":{"k8s-app": "kube-controller-manager"}}}'
kubectl -n kube-system patch service prometheus-operator-kube-scheduler -p '{"spec":{"selector":{"k8s-app": "kube-scheduler"}}}'
kubectl -n kube-system patch service prometheus-operator-kube-controller-manager --type=json -p='[{"op": "remove", "path": "/spec/selector/component"}]'
kubectl -n kube-system patch service prometheus-operator-kube-scheduler --type=json -p='[{"op": "remove", "path": "/spec/selector/component"}]'
```

## Filter metrics

The `overrides.yaml` file specifies metrics to be collected. If you want to exclude some metrics from collection, or include others, you can edit `overrides.yaml`. The file contains a section like the following for each of the Kubernetes components that report metrics in this solution: API server, Controller Manager, and so on.

If you would like to collect other metrics that are not listed in `overrides.yaml`, you can add a new section to the file.

```yaml
    - url: http://fluentd:9888/prometheus.metrics.<some_label>
      writeRelabelConfigs:
      - action: keep
        regex: <metric1>|<metric2>|...
        sourceLabels: [__name__]
```

The syntax of `writeRelabelConfigs` can be found [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write).
You can supply any label you like. You can query Prometheus to see a complete list of metrics it’s scraping.

## Trim and relabel metrics

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

This:

* Trims the service metadata from the metric datapoint.
* Rename* the label/metadata `container_name` to `container`, and `pod_name` to `pod`.
* Filters out metrics for which the namespace is not `kube-system`.

## Tear down

To delete `prometheus-operator` from the Kubernetes cluster:

```sh
helm del --purge prometheus-operator
```

__NOTE__ This command will not remove the Custom Resource Definitions created.

To delete the `fluentd-sumologic` app:

```sh
kubectl delete -f ./fluentd-sumologic.yaml
```

To delete the `metric-endpoints` secrets (for recreating collector/sources):

```sh
kubectl -n sumologic delete secret metric-endpoints
```

To delete the `sumologic` namespace and all resources under it:

```sh
kubectl delete namespace sumologic
```

# Debugging the Kubernetes Collection Pipeline

## General steps for debugging issues

#### Note about namespaces

The following `kubectl` commands assume you are in the correct namespace `sumologic`. By default, these commands will use the namespace `default`.

To run a single command in the `sumologic` namespace, pass in the flag `-n sumologic`.

To set your namespace context more permanently, you can run
```
kubectl config set-context $(kubectl config current-context) --namespace=sumologic
```

### 1. Use `kubectl` to get logs and state

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

#### Fluentd Logs

```
kubectl logs fluentd-xxxxxxxxx-xxxxx -f
```

To enable more detailed debug and/or trace logs from Fluentd, add the following lines to the `fluentd-sumologic.yaml` file under the relevant `.conf` section:
```
<system>
  log_level trace # or debug
</system>
```
After which you'll begin to see the relevant logs.

#### Pod stuck in `ContainerCreating` state

If you are seeing a pod stuck in the `ContainerCreating` state and seeing logs like
```
Warning  FailedCreatePodSandBox  29s   kubelet, ip-172-20-87-45.us-west-1.compute.internal  Failed create pod sandbox: rpc error: code = DeadlineExceeded desc = context deadline exceeded
```
you have an unhealthy node. Killing the node should resolve this issue.

#### [Metrics] Prometheus Logs
```
kubectl logs prometheus-prometheus-operator-prometheus-0 prometheus -f
```

### 2. Send data to Fluentd stdout instead of to Sumo

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
```
kubectl delete deployment fluentd
kubectl apply -f /path/to/fluentd-sumologic.yaml
```

__Note__ this `-f` flag stands for "file" rather than "follow" like in the logs command above.

You should see data being sent to Fluentd logs, which you can get using the commands [above](#fluentd-logs).

### 3. [Metrics] Check the Prometheus UI

First run the following command to expose the Prometheus UI:
```
kubectl port-forward prometheus-prometheus-operator-prometheus-0 8080:9090
```

Then, in your browser, go to `localhost:8080`. You should be in the Prometheus UI now.

In the top menu, navigate to section `Status > Targets`. Check if any targets are down or have errors.

## Missing `kubelet` metrics

Navigate to the `kubelet` targets using the steps above. You may see that the targets are down with 401 errors. If so, there are two known workarounds you can try.

### 1. Enable the `authenticationTokenWebhook` flag in the cluster

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

### 2. Disable the `kubelet.serviceMonitor.https` flag in the Prometheus operator

The goal is to set the flag `kubelet.serviceMonitor.https=false` when deploying the prometheus operator.

In your `overrides.yaml` file, add
```
kubelet:
  serviceMonitor:
    https: false
```

and redeploy Prometheus:
```
helm del --purge prometheus-operator
helm install stable/prometheus-operator --name prometheus-operator --namespace sumologic -f /path/to/overrides.yaml
```

## Missing `kube-controller-manager` or `kube-scheduler` metrics

There’s an issue with backwards compatibility in the current version of the prometheus-operator helm chart that requires us to override the selectors for kube-scheduler and kube-controller-manager in order to see metrics from them. If you are not seeing metrics from these two targets, try running the commands in the "Configure Prometheus" section [above](#missing-metrics-for-controller-manager-or-scheduler).
