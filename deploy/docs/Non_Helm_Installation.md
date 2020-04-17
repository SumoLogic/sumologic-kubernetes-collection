# Non Helm Installation

This document has instructions for setting up collection with Fluentd, FluentBit, and Prometheus.

<!-- TOC -->

- [Before you start](#before-you-start) 
- [Create Sumo Fields and a collector](#create-sumo-fields-a-collector) 
  - [Automatic Source Creation and Setup YAML](#automatic-source-creation-and-setup-yaml) 
  - [Manual Source Creation and Setup](#manual-source-creation-and-setup) 
    - [Create a Hosted Collector and an HTTP Source](#create-a-hosted-collector-and-an-http-source) 
    - [Create the namespace and secret](#create-the-namespace-and-secret) 
- [Deploy Fluentd](#deploy-fluentd) 
  - [Use default configuration](#use-default-configuration) 
  - [Customize configuration](#customize-configuration) 
  - [Verify the pods are running](#verify-the-pods-are-running) 
- [Deploy Prometheus](#deploy-prometheus) 
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

*Note the following steps are one way to install Helm, but in order to ensure property security, please be sure to review the [Helm documentation.](https://v2.helm.sh/docs/securing_installation/#securing-your-helm-installation)*

Download the latest Helm 2 version to generate the yaml files necessary to deploy by running

```bash
brew install helm@2
export PATH="/usr/local/opt/helm@2/bin:$PATH"
```

Reference: https://v2.helm.sh/docs/using_helm/#installing-helm

__NOTE__ These instructions assume that Prometheus is not already running on your Kubernetes cluster.

## Create Sumo Fields and a Collector

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

### Automatic Source Creation and Setup YAML

This approach requires access to the Sumo Logic Collector API. It will create Kubernetes resources in your environment and run a container that uses the [Sumo Logic Terraform provider](https://github.com/SumoLogic/sumologic-terraform-provider) to create a Hosted Collector and multiple HTTP Sources in Sumo. It also uses the [Kubernetes Terraform provider](https://www.terraform.io/docs/providers/kubernetes/index.html) to create a Kubernetes secret to store the HTTP source endpoints to be used by Fluentd later.

First, create the namespace. (We recommend using `sumologic` for easier setup.)
```sh
kubectl create namespace sumologic
``` 

Run the following command to download and apply the YAML file containing all the Kubernetes resources. Replace the `<NAMESPACE>`, `<SUMOLOGIC_ACCESSID>`, `<SUMOLOGIC_ACCESSKEY>`, `<COLLECTOR_NAME>` and `<CLUSTER_NAME>` variables with your values.

```sh
curl -s https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v0.17/deploy/kubernetes/setup-sumologic.yaml.tmpl | \
sed 's/\$NAMESPACE'"/<NAMESPACE>/g" | \
sed 's/\$SUMOLOGIC_ACCESSID'"/<SUMOLOGIC_ACCESSID>/g" | \
sed 's/\$SUMOLOGIC_ACCESSKEY'"/<SUMOLOGIC_ACCESSKEY>/g" | \
sed 's/\$COLLECTOR_NAME'"/<COLLECTOR_NAME>/g" | \
sed 's/\$CLUSTER_NAME'"/<CLUSTER_NAME>/g" | \
tee setup-sumologic.yaml | \
kubectl -n sumologic apply -f -
```

Run the following command to make sure the `collection-sumologic-setup` job is completed. You should see the status of the job being `Completed`.
```sh
kubectl get jobs -n sumologic
```

(Optional) You can delete the setup job which will automatically delete the associated pod as well.
```sh
kubectl delete job collection-sumologic-setup -n sumologic
```

Next, you will set up [Fluentd](#deploy-fluentd).

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

#### Create the namespace and secret

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

## Deploy Fluentd

In this step you will deploy Fluentd using a Sumo-provided .yaml manifest. 

### Use default configuration

If you don't need to customize the configuration apply the `fluentd-sumologic.yaml` manifest with the following command. Replace the `<NAMESPACE>` and `<CLUSTER_NAME>` variables with your values.

```sh
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v0.17/deploy/kubernetes/fluentd-sumologic.yaml.tmpl | \
sed 's/\$NAMESPACE'"/sumologic/g" | \
sed 's/cluster kubernetes/cluster $CLUSTER_NAME/g' | \
kubectl -n sumologic apply -f -
```

### Customize configuration

If you need to customize the configuration there are two commands to run. First, get the `fluentd-sumologic.yaml` manifest with following command:

```sh
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v0.17/deploy/kubernetes/fluentd-sumologic.yaml.tmpl | \
sed 's/\$NAMESPACE'"/sumologic/g" >> fluentd-sumologic.yaml
```

Next, customize the provided YAML file. Our [plugin](../../fluent-plugin-events/README.md#fluent-plugin-events) allows you to configure fields for events. Once done run the following command to apply the `fluentd-sumologic.yaml` manifest.

```sh
kubectl -n sumologic apply -f fluentd-sumologic.yaml
```

The manifest will create the Kubernetes resources required by Fluentd.


### Verify the pods are running

```sh
kubectl -n sumologic get pod
```

Next, you will set up [Prometheus](#deploy-prometheus).

## Deploy Prometheus

In this step, you will configure the Prometheus server to write metrics to Fluentd.

Download the Prometheus Operator `prometheus-overrides.yaml` by running

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v0.17/deploy/helm/prometheus-overrides.yaml
```

__NOTE__ If you plan to install Prometheus in a different namespace than you deployed Fluentd to in Step 1, or you have an existing Prometheus you plan to apply our configuration to running in a different namespace,  please update the remote write API configuration to use the full service URL like, `http://collection-sumologic.sumologic.svc.cluster.local:9888`.

You can also [Filter metrics](additional_prometheus_configuration.md#filter-metrics) and [Trim and relabel metrics](additional_prometheus_configuration.md#trim-and-relabel-metrics) in `prometheus-overrides.yaml`.

Install `prometheus-operator` by generating the yaml files using Helm:

```bash
$ helm fetch stable/prometheus-operator --version 8.2.0
$ helm template prometheus-operator-8.2.0.tgz --name prometheus-operator --namespace=sumologic -f prometheus-overrides.yaml > prometheus.yaml
```

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

Before applying, change your default namespace for `kubectl` from `default` to `sumologic`. This is required as the YAML generated will deploy some resources to `kube-system` namespace as well.

```bash
$ kubectl config set-context --current --namespace=sumologic
$ kubectl apply -f prometheus.yaml
```

Verify `prometheus-operator` is running:

```sh
kubectl -n sumologic logs prometheus-collection-prometheus-oper-prometheus-0 prometheus -f
```

At this point setup is complete and metrics data is being sent to Sumo Logic.

__NOTE__ You can also [send custom metrics](additional_prometheus_configuration.md#custom-metrics)to Sumo Logic from Prometheus.

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

Run the following commands to download the FluentBit `fluent-bit-overrides.yaml` file and install `fluent-bit`

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v0.17/deploy/helm/fluent-bit-overrides.yaml
$ helm fetch stable/fluent-bit --version 2.8.1
$ helm template fluent-bit-2.8.1.tgz --name fluent-bit --namespace=sumologic -f fluent-bit-overrides.yaml > fluent-bit.yaml
$ kubectl apply -f fluent-bit.yaml
```

You may see the following errors while applying the `yaml` : 

```bash
unable to recognize "fluent-bit.yaml": no matches for kind "ClusterRole" in version "rbac.authorization.k8s.io/v1alpha1"
unable to recognize "fluent-bit.yaml": no matches for kind "ClusterRoleBinding" in version "rbac.authorization.k8s.io/v1alpha1"
```
The above errors can be ignored.

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

## Deploy Falco

In this step, you will deploy [Falco](https://falco.org/) to detect anomalous activity and capture Kubernetes Audit Events. This step is required only if you intend to use the Sumo Logic Kubernetes App.

Download the file `falco-overrides.yaml` from GitHub:

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v0.17/deploy/helm/falco-overrides.yaml
$ helm fetch stable/falco --version 1.0.9
$ helm template falco-1.0.9.tgz --name falco --namespace=sumologic -f falco-overrides.yaml > falco.yaml
$ kubectl apply -f falco.yaml
```

__NOTE__ Refer to the [requirements.yaml](../helm/sumologic/requirements.yaml) for the currently supported version.

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
