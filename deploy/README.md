# Deployment Guide

This page has instructions for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic.

**Compatibility**: Kubernetes version 1.11+

<!-- TOC -->

- [Deployment Guide](#deployment-guide)
    - [Solution overview](#solution-overview)
    - [Before you start](#before-you-start)
    - [Step 1: Create Sumo collector and deploy Fluentd](#step-1-create-sumo-collector-and-deploy-fluentd)
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
        - [Missing metrics for `controller-manager` or `scheduler`](#missing-metrics-for-controller-manager-or-scheduler)
        - [Additional configuration options](#additional-configuration-options)
            - [Filter metrics](#filter-metrics)
            - [Trim and relabel metrics](#trim-and-relabel-metrics)
            - [Custom Metrics](#custom-metrics)
                - [Step 1: Expose a `/metrics` endpoint on your service](#step-1-expose-a-metrics-endpoint-on-your-service)
                - [Step 2: Setup a service monitor so that Prometheus pulls the data](#step-2-setup-a-service-monitor-so-that-prometheus-pulls-the-data)
                - [Step 3: Update the prometheus-overrides.yaml file to forward the metrics to Sumo.](#step-3-update-the-prometheus-overridesyaml-file-to-forward-the-metrics-to-sumo)
    - [Step 3: Deploy FluentBit](#step-3-deploy-fluentbit)
    - [Tear down](#tear-down)
- [Troubleshooting Collection](#troubleshooting-collection)
    - [Namespace configuration](#namespace-configuration)
    - [Gathering logs](#gathering-logs)
        - [Fluentd Logs](#fluentd-logs)
        - [Prometheus Logs](#prometheus-logs)
        - [Send data to Fluentd stdout instead of to Sumo](#send-data-to-fluentd-stdout-instead-of-to-sumo)
    - [Gathering metrics](#gathering-metrics)
        - [Check the `/metrics` endpoint](#check-the-metrics-endpoint)
        - [Check the Prometheus UI](#check-the-prometheus-ui)
        - [Check Prometheus Remote Storage](#check-prometheus-remote-storage)
        - [Check FluentBit and FluentD output metrics](#check-fluentbit-and-fluentd-output-metrics)
    - [Common Issues](#common-issues)
        - [Pod stuck in `ContainerCreating` state](#pod-stuck-in-containercreating-state)
        - [Missing `kubelet` metrics](#missing-kubelet-metrics)
            - [1. Enable the `authenticationTokenWebhook` flag in the cluster](#1-enable-the-authenticationtokenwebhook-flag-in-the-cluster)
            - [2. Disable the `kubelet.serviceMonitor.https` flag in the Prometheus operator](#2-disable-the-kubeletservicemonitorhttps-flag-in-the-prometheus-operator)
        - [Missing `kube-controller-manager` or `kube-scheduler` metrics](#missing-kube-controller-manager-or-kube-scheduler-metrics)

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
* **Fluentd deployment.** Forwards metrics to HTTP sources on a hosted collector. Includes multiple Fluentd plugins that parse and format the metrics and enrich them with metadata.

## Before you start

* If you haven’t already done so, create your Kubernetes cluster. Verify that you can access the cluster with `kubectl`.
* Verify that the cluster DNS service is enabled. For more information, see [DNS](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/#dns) in Kubernetes documentation.
* Verify that you are in the correct context. You can check your current context and set your desired context with:
```
kubectl config current-context
kubectl config use-context DESIRED_CONTEXT_NAME
```

__NOTE__ These instructions assume that Prometheus is not already running on your Kubernetes cluster.

## Step 1: Create Sumo collector and deploy Fluentd

In this step you create a Sumo Logic Hosted Collector with a set of HTTP Sources to receive your Kubernetes metrics; creates Kubernetes secrets for the HTTP sources created; and deploy Fluentd using a Sumo-provided .yaml manifest.

### Automatic Source Creation and Setup Script

This approach requires access to the Sumo Logic Collector API. It will create a Hosted Collector and multiple HTTP Source endpoints and pre-populate Kubernetes secrets detailed in the manual steps below.

```sh
curl -s https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/setup.sh \
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


### Verify the pods are running

```sh
kubectl -n sumologic get pod
```

## Step 2: Configure Prometheus

In this step, you will configure the Prometheus server to write metrics to Fluentd.

Install Helm:

*Note the following steps are one way to install Helm, but in order to ensure property security, please be sure to review the [Helm documentation.](https://helm.sh/docs/using_helm/#securing-your-helm-installation)*

```sh
brew install kubernetes-helm
```

Apply `tiller-rbac.yaml` manifest with `kubectl`, and deploy Tiller with a service account:

```sh
kubectl apply -f https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/tiller-rbac.yaml \
  && helm init --service-account tiller
```

This manifest binds the default `cluster-admin` ClusterRole in your Kubernetes cluster to the `tiller` service account (which is created when you deploy Tiller in the following step.)

Download the Prometheus Operator `prometheus-overrides.yaml` from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/prometheus-overrides.yaml
```

Before installing `prometheus-operator`, edit `prometheus-overrides.yaml` to define a unique cluster identifier. The default value of the `cluster` field in the `externalLabels` section of `prometheus-overrides.yaml` is `kubernetes`. If you will be deploying the metric collection solution on multiple Kubernetes clusters, you will want to use a unique identifier for each. For example, you might use “Dev”, “Prod”, and so on.

__NOTE__ It’s fine to change the value of the `cluster` field, but don’t change the field name (key).

__NOTE__ If you plan to install Prometheus in a different namespace than you deployed FluentD to in Step 1, or you have an existing Prometheus you plan to apply our configuration to running in a different namespace,  please update the remote write API configuration to use the full service url. e.g. `http://fluentd.sumologic.svc.cluster.local:9888`.

You can also [Filter metrics](#filter-metrics) and [Trim and relabel metrics](#trim-and-relabel-metrics) in `prometheus-overrides.yaml`.

Install `prometheus-operator` using Helm:

```sh
helm repo update \
   && helm install stable/prometheus-operator --name prometheus-operator --namespace sumologic -f prometheus-overrides.yaml
```

__NOTE__ If Custom Resource Definitions (CRD) were created earlier, add `--no-crd-hook` to the end of the command.

Verify `prometheus-operator` is running:

```sh
kubectl -n sumologic logs prometheus-prometheus-operator-prometheus-0 prometheus -f
```

At this point setup is complete and metrics data is being sent to Sumo Logic.

### Missing metrics for `controller-manager` or `scheduler`

Since there is a backward compatibility issue in the current version of chart, you may need to follow a workaround for sending these metrics under `controller-manager` or `scheduler`:

```sh
kubectl -n kube-system patch service prometheus-operator-kube-controller-manager -p '{"spec":{"selector":{"k8s-app": "kube-controller-manager"}}}'
kubectl -n kube-system patch service prometheus-operator-kube-scheduler -p '{"spec":{"selector":{"k8s-app": "kube-scheduler"}}}'
kubectl -n kube-system patch service prometheus-operator-kube-controller-manager --type=json -p='[{"op": "remove", "path": "/spec/selector/component"}]'
kubectl -n kube-system patch service prometheus-operator-kube-scheduler --type=json -p='[{"op": "remove", "path": "/spec/selector/component"}]'
```

### Additional configuration options

### Metrics

#### Filter metrics

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

#### Trim and relabel metrics

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

### Custom Metrics

If you have custom metrics you'd like to send to Sumo via Prometheus, you just need to expose a `/metrics` endpoint in prometheus format, and instruct prometheus via a ServiceMonitor to pull data from the endpoint. In this section, we'll walk through collecting custom metrics with Prometheus.

##### Step 1: Expose a `/metrics` endpoint on your service

There are many pre-built libraries that the community has built to expose these, but really any output that aligns with the prometheus format can work. Here is a list of libraries: [Libraries](https://prometheus.io/docs/instrumenting/clientlibs). Manually verify that you have metrics exposed in Prometheus format by hitting the metrics endpoint, and verifying that the output follows the [Prometheus format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md).

##### Step 2: Setup a service monitor so that Prometheus pulls the data

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

Note, please make sure you include the label `release: prometheus-operator` in your ServiceMonitor as the Prometheus Operator expects this.  

Detailed instructions on service monitors can be found via [Prometheus-Operator](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md#related-resources) website.
Once you have created this yaml file, go ahead and run `kubectl create -f name_of_yaml.yaml -n sumologic`. This will create the service monitor in the sumologic namespace.

##### Step 3: Update the prometheus-overrides.yaml file to forward the metrics to Sumo.

The `prometheus-overrides.yaml` file controls what metrics get forwarded on to Sumo Logic. In order to get your custom metrics sending into Sumo Logic, you need to update the `prometheus-overrides.yaml` file to include a rule to forward on your custom metrics. Here is an example addition to the `prometheus-overrides.yaml` that will forward metrics to Sumo:

```
- url: http://fluentd:9888/prometheus.metrics
      writeRelabelConfigs:
      - action: keep
        regex: <YOUR_CUSTOM_MATCHER>
        sourceLabels: [__name__]
```

After adding this to the `yaml`, go ahead and run a `helm upgrade prometheus-operator stable/prometheus-operator -f prometheus-overrides.yaml` to upgrade your `prometheus-operator`.

Note: When executing the helm upgrade to avoid the error below is need add the argument `--force`.

      invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/name":"kube-state-metrics"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable

If all goes well, you should now have your custom metrics piping into Sumo Logic.

## Step 3: Deploy FluentBit

In this step, you will deploy FluentBit to forward logs to Fluentd.

Download the FluentBit `fluent-bit-overrides.yaml` from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/fluent-bit-overrides.yaml
```

Install `fluent-bit` using Helm:

```sh
helm repo update \
   && helm install stable/fluent-bit --name fluent-bit --namespace sumologic -f fluent-bit-overrides.yaml
```

## Step 4: Deploy Falco

In this step, you will deploy [Falco](https://falco.org/) to detect anomalous activity and capture Kubernetes Audit Events. This step is required only if you intend to use the Sumo Logic Kubernetes App.

__NOTE__ [Falco](https://sysdig.com/blog/sysdig-falco/) needs privileged container access to insert its kernel module to process events for system calls.

Download the file `falco-overrides.yaml` from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/falco-overrides.yaml
```

Install `falco` using Helm:

```sh
helm repo update \
   && helm install stable/falco --name falco --namespace sumologic -f falco-overrides.yaml
```

__NOTE__ `Google Kubernetes Engine (GKE)` uses Container-Optimized OS (COS) as the default operating system for its worker node pools. COS is a security-enhanced operating system that limits access to certain parts of the underlying OS. Because of this security constraint, Falco cannot insert its kernel module to process events for system calls. However, COS provides the ability to leverage eBPF (extended Berkeley Packet Filter) to supply the stream of system calls to the Falco engine. eBPF is currently supported only on GKE and COS. More details [here](https://falco.org/docs/installation/).

To install `Falco` on `GKE`, uncomment following lines in the file `falco-overrides.yaml`:

```
ebpf:
  enabled: true
```

Install `falco` on `GKE` using Helm:

```sh
helm repo update \
   && helm install stable/falco --name falco --namespace sumologic -f falco-overrides.yaml
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
