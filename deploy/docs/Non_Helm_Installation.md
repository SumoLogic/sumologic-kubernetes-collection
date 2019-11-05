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
  - [Missing metrics for `controller-manager` or `scheduler`](#missing-metrics-for-`controller-manager`-or-`scheduler`) 
  - [Additional configuration options](#additional-configuration-options) 
  - [Metrics](#metrics) 
    - [Filter metrics](#filter-metrics) 
    - [Trim and relabel metrics](#trim-and-relabel-metrics) 
  - [Custom Metrics](#custom-metrics) 
    - [Expose a `/metrics` endpoint on your service](#expose-a-`/metrics`-endpoint-on-your-service) 
    - [Set up a service monitor so that Prometheus pulls the data](#set-up-a-service-monitor-so-that-prometheus-pulls-the-data) 
    - [Create a new HTTP source in Sumo Logic.](#create-a-new-http-source-in-sumo-logic.) 
    - [Update the metrics.conf FluentD Configuration](#update-the-metrics.conf-fluentd-configuration) 
    - [Update the prometheus-overrides.yaml file to forward the metrics to FluentD.](#update-the-prometheus-overrides.yaml-file-to-forward-the-metrics-to-fluentd.) 
- [Deploy FluentBit](#deploy-fluentbit) 
- [Deploy Falco](#4-deploy-falco)
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

## Configure Prometheus

In this step, you will configure the Prometheus server to write metrics to Fluentd.

Download the Prometheus Operator `prometheus-overrides.yaml` by running

```bash
$ cd /path/to/helm/charts/  
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.10.0/deploy/helm/prometheus-overrides.yaml
```

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

#### Expose a `/metrics` endpoint on your service

There are many pre-built libraries that the community has built to expose these, but really any output that aligns with the prometheus format can work. Here is a list of libraries: [Libraries](https://prometheus.io/docs/instrumenting/clientlibs). Manually verify that you have metrics exposed in Prometheus format by hitting the metrics endpoint, and verifying that the output follows the [Prometheus format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md).

#### Set up a service monitor so that Prometheus pulls the data

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

#### Create a new HTTP source in Sumo Logic.

To avoid [blacklisting](https://help.sumologic.com/Metrics/Understand_and_Manage_Metric_Volume/Blacklisted_Metrics_Sources) metrics should be distributed across multiple HTTP sources. You can [follow these steps](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) to create a new HTTP source for your custom metrics. Make note of the URL as you will need it in the next step.

#### Update the metrics.conf FluentD Configuration

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

#### Update the prometheus-overrides.yaml file to forward the metrics to FluentD.

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

## Deploy FluentBit

In this step, you will deploy FluentBit to forward logs to Fluentd.

Run the following commands to download the FluentBit fluent-bit-overrides.yaml file and install `fluent-bit`

```bash
$ cd /path/to/helm/charts/
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.10.0/deploy/helm/fluent-bit-overrides.yaml
$ helm template stable/fluent-bit --name fluent-bit --set dryRun=true -f fluent-bit-overrides.yaml > fluent-bit.yaml
$ kubectl apply -f fluent-bit.yaml
```

## Deploy Falco

In this step, you will deploy [Falco](https://falco.org/) to detect anomalous activity and capture Kubernetes Audit Events. This step is required only if you intend to use the Sumo Logic Kubernetes App.

Download the file `falco-overrides.yaml` from GitHub:

```bash
$ cd /path/to/helm/charts/
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.10.0/deploy/helm/falco-overrides.yaml
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
