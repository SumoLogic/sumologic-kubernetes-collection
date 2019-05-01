# Deployment Guide 

This page has instructions for collecting Kubernetes metrics; enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic.

__NOTE__ This page describes preview software. If you have comments or issues, please add an issue here: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues.

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

__NOTE__ These instructions assume that  Prometheus is not already running on your Kubernetes cluster.

## Step 1: Create hosted collector and HTTP sources 
In this step you create a Sumo Logic hosted collector with a set of HTTP sources to receive your Kubernetes metrics. 

**To create a hosted collector and an HTTP source**

Create a hosted collector, following the instructions on [Configure a Hosted Collector](https://help.sumologic.com/03Send-Data/Hosted-Collectors/Configure-a-Hosted-Collector) in Sumo help. (If you already have a Sumo hosted collector that you want to use, skip this step.)

Create 8 HTTP sources on the collector you created in the previous step, one for each of the Kubernetes components that report metrics in this solution:
* API server
* cAdvisor
* Kubelet
* Controller Manager
* Scheduler
* kube-state-metrics
* node-exporter
* prometheus-operator

Follow the instructions on [HTTP Logs and Metrics Source](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in Sumo help, with the following additions:

* **Naming the sources.** You can assign any name you like to the sources, but it’s a good idea to assign a name to each source that reflects the Kubernetes component from which it receives metrics. For example, you might name the source that receives API Server metrics “k8s-API-server”.
* **HTTP Source URLs.** When you configure each HTTP source, Sumo will display the URL of the HTTP endpoint. Make a note of the URL. You will use it when you configure the Kubernetes service to send data to Sumo.

## Step 2: Deploy Fluentd
In this step you deploy Fluentd using a Sumo-provided .yaml manifest. This step also creates Kubernetes secrets for the HTTP sources created in the previous step. 

Download `fluentd-sumologic.yaml` from https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/master/deploy/kubernetes and open it in a text editor. The manifest will create the Kubernetes resources required by Fluentd, including a deployment namespace, secrets for the Sumo Logic HTTP Source URLs, and so on.
Locate these lines, in the stanza that defines the Kubernetes secrets:

```sh
stringData:
  endpoint-metrics: XXXX
  endpoint-metrics-apiserver: XXXX
  endpoint-metrics-cadvisor: XXXX
  endpoint-metrics-kubelet: XXXX
  endpoint-metrics-kube-controller-manager: XXXX
  endpoint-metrics-kube-scheduler: XXXX
  endpoint-metrics-kube-state: XXXX
  endpoint-metrics-node-exporter: XXXX
  endpoint-metrics-prometheus-operator: XXXX
  ```
 
In each `endpoint-metrics-*` line, replace the placeholder “XXXX” with the URL of the associated HTTP endpoint that you created. 

__NOTE__  The `endpoint-metrics: XXXX` line is reserved for future use. Leave as is.

Apply the .yaml file with `kubectl`:

```sh
kubectl apply -f ./fluentd-sumologic.yaml
```

Verify the pod(s) are running:

```sh
kubectl -n sumologic get pod
```

## Step 3: Configure Prometheus
In this step, you configure the Prometheus server to write metrics to Fluentd. 

Install Helm:

```sh
brew install kubernetes-helm
```

Download `tiller-rbac.yaml` from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/tiller-rbac.yaml
```

This manifest binds the default `cluster-admin` ClusterRole in your Kubernetes cluster to the `tiller` service account (which is created when you deploy Tiller in the following step.)

Apply `tiller-rbac.yaml` with `kubectl`, and deploy Tiller with a service account:

```sh
kubectl apply -f tiller-rbac.yaml \
  && helm init --service-account tiller
```

Download the Prometheus Operator `overrides.yaml` from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/overrides.yaml
```

Before installing `prometheus-operator`, edit `overrides.yaml` to define a unique cluster identifier. The default value of the `cluster` field in the `externalLabels` section of `overrides.yaml` is “kubernetes”. Assuming you’ll deploying the metric collection solution to multiple Kubernetes clusters, you want to have a unique identifier for each. For example, you might use “Dev”, “Prod”, and so on.

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

## Filter metrics 

The `overrides.yaml` file specifies metrics to be collected. If you want to exclude some metrics from collection, or include others, you can edit `overrides.yaml`. The file contains a section like the following for each of the Kubernetes components that report metrics in this solution: API server, Controller Manager, and so on. 

The regex section is a pipe-delimited list of metrics. If you don’t want to collect a metric, delete it from the list. Make sure that after your edits, the metrics in the list are separated by exactly one pipe (|) character.

```sh
- url: http://fluentd:9888/prometheus.metrics.container
      writeRelabelConfigs:
      - action: keep
        regex: container_cpu_load_average_10s|container_cpu_system_seconds_total|container_cpu_usage_seconds_total|container_cpu_cfs_throttled_seconds_total|container_memory_usage_bytes|container_spec_memory_limit_bytes|container_memory_swap|container_spec_memory_swap_limit_bytes|container_spec_memory_reservation_limit_bytes|container_fs_usage_bytes|container_fs_limit_bytes|container_fs_writes_bytes_total|container_fs_reads_bytes_total|container_network_receive_bytes_total|container_network_transmit_bytes_total|container_network_receive_errors_total|container_network_transmit_errors_total
        sourceLabels: [__name__]
```

If you would like to collect other metrics that are not listed in `overrides.yaml`, you can add a new section to the file.

```sh
- url: http://fluentd:9888/prometheus.metrics.<some_label>
      writeRelabelConfigs:
      - action: keep
        regex: <metric1>|<metric2>|...
        sourceLabels: [__name__]
```       

You can supply any label you like. You can query Prometheus to see a complete list of metrics it’s scraping. 

## Trim and relabel metrics

You can specify relabeling, and additional inclusion or exclusion options in `fluentd-sumologic.yaml`.

The options you can use are described on https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/master/fluent-plugin-carbon-v2. 

Make your edits in the `<filter>` stanza in the ConfigMap section of `fluentd-sumologic.yaml`.

```sh
<filter prometheus.datapoint.**>
  @type carbon_v2
</filter>
```

You can use  inclusion  or  exclusion configuration options to further filter metrics by labels. For example:

```sh
<filter prometheus.datapoint.**>
  @type carbon_v2
  relabel {"service": "", "kubernetes.service.name" : "service_name", "kubernetes.pod.name" : "pod_name"}
  inclusions { "namespace" : "kube-system" }
</filter>
```

This:

* Trims the service metadata from the metric datapoint.
* Rename* the label/metadata `kubernetes.service.name` to `service_name`, and `kubernetes.pod.name` to `pod_name`.
* Filters out metrics for which the namespace is not `kube-system`.


## Tear down

To delete `prometheus-operator` from the Kubernetes cluster:


```sh
helm del --purge prometheus-operator
```
To delete the `fluentd-sumologic` app:


```sh
kubectl delete -f ./fluentd-sumologic.yaml
```

