# Deployment Guide

This page has instructions for collecting Kubernetes metrics; enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic.

__NOTE__ This page describes preview software. If you have comments or issues, please add an issue [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/issues).

## Solution overview

The diagram below illustrates the components of the Kubernetes metric collection solution.

![solution](/images/k8s-metrics3.png)

* **K8S API Server**. Exposes API server metrics.
* **Scheduler.** Makes Scheduler metrics available on an HTTP metrics port.
* **Controller Manager.** Makes Controller Manager metrics available on an HTTP metrics port.
* **node-exporter.** The `node_exporter` add-on exposes node metrics, including CPU, memory, disk, and network utilization.
* **kube-state-metrics.** Listens to the Kubernetes API server; generates metrics about the state of the deployments, nodes and pods in the cluster; and exports the metrics as plaintext on an HTTP endpoint listen port.
* **Prometheus deployment.** Scrapes the metrics exposed by the n`ode-exporter` add-on for Kubernetes and the `kube-state-metric`s component; writes metrics to a port on the Fluentd deployment.
* **Fluentd deployment.** Forwards metrics to HTTP sources on a hosted collector. Includes multiple Fluentd plugins that parse and format the metrics and enrich them with metadata.

## Before you start

* If you haven’t already done so, create your Kubernetes cluster. Verify that you can access the cluster with `kubectl`.
* Verify that the cluster DNS service is enabled. For more information, see [DNS](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/#dns) in Kubernetes documentation.

__NOTE__ These instructions assume that Prometheus is not already running on your Kubernetes cluster.

## Step 1: Create Sumo collector and deploy Fluentd

In this step you create a Sumo Logic hosted collector with a set of HTTP sources to receive your Kubernetes metrics; creates Kubernetes secrets for the HTTP sources created; and deploy Fluentd using a Sumo-provided .yaml manifest.

### Automatic with setup script

This approach requires the access to Sumo Logic API.

```sh
curl -s https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/setup.sh | bash -s <api-endpoint> <access-id> <access-key> [collector-name]
```

### Parameters

* __api-endpoint__ - required. The API endpoint from [this page](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security).
* __access-id__ - required. Sumo [access id](https://help.sumologic.com/Manage/Security/Access-Keys)
* __access-key__ - required. Sumo [access key](https://help.sumologic.com/Manage/Security/Access-Keys)
* __collector-name__ - optional. Name of Sumo collector will be created. If not specified, will be names as `kubernetes-<timestamp>`

### Manual

This is a manual alternative approach for the automatic script if you don't have API access or need customized configuration (like using an exist collector).

#### 1.1 Create a hosted collector and an HTTP source

In this step you create a Sumo Logic hosted collector with a set of HTTP sources to receive your Kubernetes metrics.

Create a hosted collector, following the instructions on [Configure a Hosted Collector](https://help.sumologic.com/03Send-Data/Hosted-Collectors/Configure-a-Hosted-Collector) in Sumo help. (If you already have a Sumo hosted collector that you want to use, skip this step.)

Create seveb HTTP sources on the collector you created in the previous step, one for each of the Kubernetes components that report metrics in this solution:
* API server
* Kubelet
* Controller Manager
* Scheduler
* kube-state-metrics
* node-exporter
* default

Follow the instructions on [HTTP Logs and Metrics Source](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in Sumo help, with the following additions:

* **Naming the sources.** You can assign any name you like to the sources, but it’s a good idea to assign a name to each source that reflects the Kubernetes component from which it receives metrics. For example, you might name the source that receives API Server metrics “api-server”.
* **HTTP Source URLs.** When you configure each HTTP source, Sumo will display the URL of the HTTP endpoint. Make a note of the URL. You will use it when you configure the Kubernetes service to send data to Sumo.

#### 2.2 Deploy Fluentd

In this step you deploy Fluentd using a Sumo-provided .yaml manifest. This step also creates Kubernetes secrets for the HTTP sources created in the previous step.

Run following command to create namespace `sumologic`

```sh
kubectl create namespace sumologic
```

Run following command to create Kubernetes secrets contains 7 HTTP source URLs just created.

```sh
kubectl -n sumologic create secret generic sumologic \
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

__NOTE__ If credentials were created earlier, add `--no-crd-hook` to the end of the command.

Verify `prometheus-operator` is running:

```sh
kubectl -n sumologic logs prometheus-prometheus-operator-prometheus-0 prometheus -f
```

Since there is a back compatible issue in latest version of chart, you may need following workaround for sending the metrics under controller-manager and scheduler:

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
    - url: http://fluentd:9888/prometheus.metrics.state.node
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

```sh
<filter prometheus.datapoint**>
  @type prometheus_format
  relabel container_name:container,pod_name:pod
</filter>
```

Sumo is using `relabel` parameter to standardize the metadata fields (`container_name` -> `container`,`pod_name` -> `pod`).
You can use `inclusion` or `exclusion` configuration options to further filter metrics by labels. For example:

```sh
<filter prometheus.datapoint**>
  @type prometheus_format
  relabel container_name:container,pod_name:pod
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

__NOTE__ This command will not remove the credentials created.

To delete the `fluentd-sumologic` app:

```sh
kubectl delete -f ./fluentd-sumologic.yaml
```

To delete the `sumologic` namespace and all resources under it:

```sh
kubectl delete namespace sumologic
```