# Troubleshooting Collection

<!-- TOC -->

- [`helm install` hanging](#helm-install-hanging)
- [Namespace configuration](#namespace-configuration)
- [Gathering logs](#gathering-logs)
  - [Fluentd Logs](#fluentd-logs)
  - [Prometheus Logs](#prometheus-logs)
  - [Send data to Fluentd stdout instead of to Sumo](#send-data-to-fluentd-stdout-instead-of-to-sumo)
- [Gathering metrics](#gathering-metrics)
  - [Check the `/metrics` endpoint](#check-the-metrics-endpoint)
  - [Check the Prometheus UI](#check-the-prometheus-ui)
  - [Check Prometheus Remote Storage](#check-prometheus-remote-storage)
  - [Check FluentBit and Fluentd output metrics](#check-fluentbit-and-fluentd-output-metrics)
- [Common Issues](#common-issues)
  - [Pod stuck in `ContainerCreating` state](#pod-stuck-in-containercreating-state)
  - [Missing `kubelet` metrics](#missing-kubelet-metrics)
    - [1. Enable the `authenticationTokenWebhook` flag in the cluster](#1-enable-the-authenticationtokenwebhook-flag-in-the-cluster)
    - [2. Disable the `kubelet.serviceMonitor.https` flag in Kube Prometheus Stack](#2-disable-the-kubeletservicemonitorhttps-flag-in-kube-prometheus-stack)
  - [Missing `kube-controller-manager` or `kube-scheduler` metrics](#missing-kube-controller-manager-or-kube-scheduler-metrics)
  - [Prometheus stuck in `Terminating` state after running `helm del collection`](#prometheus-stuck-in-terminating-state-after-running-helm-del-collection)
  - [Errors in helm installation](#errors-in-helm-installation)
  - [Rancher](#rancher)
  - [Falco and Google Kubernetes Engine (GKE)](#falco-and-google-kubernetes-engine-gke)
  - [Falco and OpenShift](#falco-and-openshift)

<!-- /TOC -->

## `helm install` hanging

If `helm install` hangs, it usually means the pre-install setup job is failing
and is in a retry loop.
Due to a Helm limitation, errors from the setup job cannot be fed back to the `helm install` command.
Kubernetes schedules the job in a pod, so you can look at logs from the pod to see
why the job is failing.
First find the pod name in the namespace where the Helm chart is deployed:

```sh
kubectl get pods -n sumologic
```

Get the logs from that pod:

```
kubectl logs POD_NAME -f
```

If you see `Secret 'sumologic::sumologic' exists, abort.` from the logs, delete the existing secret:

```
kubectl delete secret sumologic -n sumologic
```

`helm install` should proceed after the existing secret is deleted before exhausting retries. If it did time out after exhausting retries, rerun the `helm install` command.

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
kubectl logs collection-sumologic-xxxxxxxxx-xxxxx -f
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

To enable debug or trace logs using the Helm chart, you can override the value `fluentd.logLevel`:

```sh
helm upgrade collection sumologic/sumologic --reuse-values --set fluentd.logLevel="debug"
```

For configuration changes to take effect in Fluentd, you can redeploy the pods by scaling to zero and back to the desired deployment size:

```sh
kubectl scale deployment/collection-sumologic --replicas=0
kubectl scale deployment/collection-sumologic --replicas=3
```

### Prometheus Logs

To view Prometheus logs:

```
kubectl logs prometheus-collection-prometheus-oper-prometheus-0 prometheus -f
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
kubectl scale deployment/collection-sumologic --replicas=0
kubectl scale deployment/collection-sumologic --replicas=3
```

You should see data being sent to Fluentd logs, which you can get using the commands [above](#fluentd-logs).

## Gathering metrics

### Check the `/metrics` endpoint

You can `port-forward` to a pod exposing `/metrics` endpoint and verify it is exposing Prometheus metrics:

```sh
kubectl port-forward collection-sumologic-xxxxxxxxx-xxxxx 8080:24231
```

Then, in your browser, go to `localhost:8080/metrics`. You should see Prometheus metrics exposed.

### Check the Prometheus UI

First run the following command to expose the Prometheus UI:

```sh
kubectl port-forward prometheus-collection-prometheus-oper-prometheus-0 8080:9090
```

Then, in your browser, go to `localhost:8080`. You should be in the Prometheus UI now.

From here you can start typing the expected name of a metric to see if Prometheus auto-completes the entry.

If you can't find the expected metrics, you can check if Prometheus is successfully scraping the `/metrics` endpoints. In the top menu, navigate to section `Status > Targets`. Check if any targets are down or have errors.

### Check Prometheus Remote Storage

We rely on the Prometheus [Remote Storage](https://prometheus.io/docs/prometheus/latest/storage/) integration to send metrics from Prometheus to the Fluentd collection pipeline.

You can follow [Deploy Fluentd](#prometheus-logs) to verify there are no errors during remote write.

You can also check `prometheus_remote_storage_.*` metrics to look for success/failure attempts.

### Check FluentBit and Fluentd output metrics

By default, we collect input/output plugin metrics for FluentBit, and output metrics for Fluentd that you can use to verify collection:

Relevant FluentBit metrics include:

- fluentbit_input_bytes_total
- fluentbit_input_records_total
- fluentbit_output_proc_bytes_total
- fluentbit_output_proc_records_total
- fluentbit_output_retries_total
- fluentbit_output_retries_failed_total

Relevant Fluentd metrics include:

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

#### 2. Disable the `kubelet.serviceMonitor.https` flag in Kube Prometheus Stack

The goal is to set the flag `kubelet.serviceMonitor.https=false` when deploying the prometheus operator.

Add the following lines to the `kube-prometheus-stack` section of your `values.yaml` file:

```
kube-prometheus-stack:
  ...
  kubelet:
    serviceMonitor:
      https: false
```

and upgrade the helm chart:

```
helm upgrade collection sumologic/sumologic --reuse-values --version=<RELEASE-VERSION> -f values.yaml
```

### Missing `kube-controller-manager` or `kube-scheduler` metrics

There’s an issue with backwards compatibility in the current version of the
kube-prometheus-stack helm chart that requires us to override the selectors
for kube-scheduler and kube-controller-manager in order to see metrics from them.
If you are not seeing metrics from these two targets, you can use the following config.

```yaml
kube-prometheus-stack:
  kubeControllerManager:
    service:
      selector:
        k8s-app: kube-controller-manager
  kubeScheduler:
    service:
      selector:
        k8s-app: kube-scheduler
```

### Prometheus stuck in `Terminating` state after running `helm del collection`

Delete the pod forcefully by adding `--force --grace-period=0` to the `kubectl delete pod` command.

### Rancher

If you are running the out of the box rancher monitoring setup, you cannot run our Prometheus operator alongside it. The Rancher Prometheus Operator setup will actually kill and permanently terminate our Prometheus Operator instance and will prevent the metrics system from coming up.
If you have the Rancher prometheus operator setup running, they will have to use the UI to disable it before they can install our collection process.

### Falco and Google Kubernetes Engine (GKE)

`Google Kubernetes Engine (GKE)` uses Container-Optimized OS (COS) as the default
operating system for its worker node pools.
COS is a security-enhanced operating system that limits access to certain parts of the underlying OS.
Because of this security constraint, Falco cannot insert its kernel module to process events for system calls.
However, COS provides the ability to use extended Berkeley Packet Filter (eBPF)
to supply the stream of system calls to the Falco engine.
eBPF is currently only supported on GKE and COS.
For more information see [Falco documentation](https://falco.org/docs/getting-started/third-party/#gke).

To install on `GKE`, use the provided override file to customize your configuration and uncomment the following lines in the `values.yaml` file referenced below:

```
  #ebpf:
  #  enabled: true
```

### Falco and OpenShift

Falco does not provide modules for all kernels.
When Falco module is not available for particular kernel, Falco tries to build it.
Building a module requires `kernel-devel` package installed on nodes.

For OpenShift, installation of `kernel-devel` on nodes is provided through MachineConfig used by
[Machine Config operator](https://github.com/openshift/machine-config-operator).
When update of machine configuration is needed machine is rebooted, please see
[documentation](https://github.com/openshift/machine-config-operator/blob/master/docs/MachineConfigDaemon.md#coordinating-updates).
The process of changing nodes configuration may require long time
during which Pods scheduled on unchanged nodes are in `Init` state.

Node configuration can be verified by following annotations:

- `machineconfiguration.openshift.io/currentConfig`
- `machineconfiguration.openshift.io/desiredConfig`
- `machineconfiguration.openshift.io/state`
