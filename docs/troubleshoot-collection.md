# Troubleshooting Collection

<!-- TOC -->

- [Troubleshooting Installation](#troubleshooting-installation)
- [Namespace configuration](#namespace-configuration)
- [Collecting logs](#collecting-logs)
  - [Check log throttling](#check-log-throttling)
  - [Check ingest budget limits](#check-ingest-budget-limits)
  - [Check if collection pods are in a healthy state](#check-if-collection-pods-are-in-a-healthy-state)
  - [Prometheus Logs](#prometheus-logs)
  - [OpenTelemetry Logs Collector is being CPU throttled](#opentelemetry-logs-collector-is-being-cpu-throttled)
- [Collecting metrics](#collecting-metrics)
  - [Check the `/metrics` endpoint](#check-the-metrics-endpoint)
  - [Check the `/metrics` endpoint for Kubernetes services](#check-the-metrics-endpoint-for-kubernetes-services)
  - [Check the Prometheus UI](#check-the-prometheus-ui)
  - [Check Prometheus Remote Storage](#check-prometheus-remote-storage)
- [Common Issues](#common-issues)
  - [Missing metrics - cannot see cluster in Explore](#missing-metrics---cannot-see-cluster-in-explore)
  - [Pod stuck in `ContainerCreating` state](#pod-stuck-in-containercreating-state)
  - [Missing `kubelet` metrics](#missing-kubelet-metrics)
    - [1. Enable the `authenticationTokenWebhook` flag in the cluster](#1-enable-the-authenticationtokenwebhook-flag-in-the-cluster)
    - [2. Disable the `kubelet.serviceMonitor.https` flag in Kube Prometheus Stack](#2-disable-the-kubeletservicemonitorhttps-flag-in-kube-prometheus-stack)
  - [Missing `kube-controller-manager` or `kube-scheduler` metrics](#missing-kube-controller-manager-or-kube-scheduler-metrics)
  - [Prometheus stuck in `Terminating` state after running `helm del collection`](#prometheus-stuck-in-terminating-state-after-running-helm-del-collection)
  - [Rancher](#rancher)
  - [Falco and Google Kubernetes Engine (GKE)](#falco-and-google-kubernetes-engine-gke)
  - [Falco and OpenShift](#falco-and-openshift)
  - [Out of memory (OOM) failures for Prometheus Pod](#out-of-memory-oom-failures-for-prometheus-pod)
  - [Prometheus: server returned HTTP status 404 Not Found: 404 page not found](#prometheus-server-returned-http-status-404-not-found-404-page-not-found)
  - [OpenTelemetry: dial tcp: lookup collection-sumologic-metadata-logs.sumologic.svc.cluster.local.: device or resource busy](#opentelemetry-dial-tcp-lookup-collection-sumologic-metadata-logssumologicsvcclusterlocal-device-or-resource-busy)

<!-- /TOC -->

## Troubleshooting Installation

Please refer to [the Troubleshooting Installation section in Installation document](/docs/installation.md#troubleshooting-installation)

## Namespace configuration

The following `kubectl` commands assume you are in the correct namespace `sumologic`. By default, these commands will use the namespace
`default`.

To run a single command in the `sumologic` namespace, pass in the flag `-n sumologic`.

To set your namespace context more permanently, you can run

```sh
kubectl config set-context $(kubectl config current-context) --namespace=sumologic
```

## Collecting logs

If you cannot see logs in Sumo that you expect to be there, here are the things to check.

### Check log throttling

Check if [log throttling][log_throttling] is happening.

If it is, there will be messages like `HTTP ERROR 429 You have temporarily exceeded your Sumo Logic quota` in OpenTelemetry Collector logs.

[log_throttling]: https://help.sumologic.com/docs/manage/ingestion-volume/log-ingestion#log-throttling

### Check ingest budget limits

Check if an [ingest budget][ingest_budgets] limit is hit.

If it is, there will be `budget.exceeded` messages from Sumo in OpenTelemetry Collector logs, similar to the following:

```console
2022-04-12 13:47:17 +0000 [warn]: #0 There was an issue sending data: id: KMZJI-FCDPN-4KHKD, code: budget.exceeded, status: 200, message: Message(s) in the request dropped due to exceeded budget.
```

[ingest_budgets]: https://help.sumologic.com/docs/manage/ingestion-volume/ingest-budgets

### Check if collection pods are in a healthy state

Run:

```
kubectl get pods
```

to get a list of running pods. If any of them are not in the `Status: running` state, something is wrong. To get the logs for that pod, you
can either:

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

### Prometheus Logs

To view Prometheus logs:

```sh
kubectl -n "${NAMESPACE}" logs -l app.kubernetes.io/name=prometheus --container prometheus -f
```

Where `collection` is the `helm` release name.

### OpenTelemetry Logs Collector is being CPU throttled

If OpenTelemtry Logs Collector is being throttled, you should increase CPU request to higher value, for example:

```yaml
otellogs:
  daemonset:
    resources:
      requests:
        cpu: 2
      limits:
        cpu: 5
```

If this situation affects only specific group of nodes, you can change resource configuration only for them:

```yaml
otellogs:
  additionalDaemonSets:
    ## intense will be suffix for daemonset for easier recognition
    intense:
      nodeSelector:
        ## we are using nodeSelector to select only nodes with `workingGroup` label set to `IntenseLogGeneration`
        workingGroup: IntenseLogGeneration
      resources:
        requests:
          cpu: 1
        limits:
          cpu: 10
  daemonset:
    # For main daemonset, we need to set nodeAffinity to not schedule on nodes with `workingGroup` label set to `IntenseLogGeneration`
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: workingGroup
                  operator: NotIn
                  values:
                    - IntenseLogGeneration
```

For more information look at the `Setting different resources on different nodes for logs collector` section in
[Advanced Configuration / Best Practices](/docs/best-practices.md#setting-different-resources-on-different-nodes-for-logs-collector)
document.

## Collecting metrics

### Check the `/metrics` endpoint

You can `port-forward` to a pod exposing `/metrics` endpoint and verify it is exposing Prometheus metrics:

```sh
kubectl port-forward collection-sumologic-xxxxxxxxx-xxxxx 8080:24231
```

Then, in your browser, go to `http://localhost:8080/metrics`. You should see Prometheus metrics exposed.

#### Check the `/metrics` endpoint for Kubernetes services

For kubernetes services you can use the following way:

1. Create `sumologic-debug` pod

   ```bash
   cat << EOF | kubectl apply -f -
   apiVersion: v1
   kind: Pod
   metadata:
     name: sumologic-debug
     namespace: <namespace you want to create pod in (e.g. sumologic)>
   spec:
     containers:
     - args:
       - receiver-mock
       image: sumologic/kubernetes-tools:2.9.0
       imagePullPolicy: IfNotPresent
       name: debug
     serviceAccountName: <service account name used by prometheus (e.g. collection-kube-prometheus-prometheus)>
   EOF
   ```

2. Go into the container:

   ```bash
   kubectl exec -it sumologic-debug -n <namespace> bash

   ```

3. Talk with API directly like prometheus does, e.g.

   ```bash
   curl https://10.0.2.15:10250/metrics/cadvisor --insecure --cacert /var/run/secrets kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
   ```

### Check the Prometheus UI

First run the following command to expose the Prometheus UI:

```sh
$ kubectl -n "${NAMESPACE}" get pod -l app.kubernetes.io/name=prometheus
NAME                                                 READY   STATUS    RESTARTS   AGE
prometheus-collection-kube-prometheus-prometheus-0   2/2     Running   0          13m
$ kubectl -n "${NAMESPACE}" port-forward prometheus-collection-kube-prometheus-prometheus-0 8080:9090
Forwarding from 127.0.0.1:8080 -> 9090
Forwarding from [::1]:8080 -> 9090
```

Then, in your browser, go to `localhost:8080`. You should be in the Prometheus UI now.

From here you can start typing the expected name of a metric to see if Prometheus auto-completes the entry.

If you can't find the expected metrics, ensure that prometheus configuration is correct and up to date. In the top menu, navigate to section
`Status > Configuration` or go to the `http://localhost:8080/config`. Review the configuration.

Next, you can check if Prometheus is successfully scraping the `/metrics` endpoints. In the top menu, navigate to section `Status > Targets`
or go to the `http://localhost:8080/targets`. Check if any targets are down or have errors.

### Check Prometheus Remote Storage

We rely on the Prometheus [Remote Storage](https://prometheus.io/docs/prometheus/latest/storage/) integration to send metrics from
Prometheus to the metadata enrichment service.

You [check Prometheus logs](#prometheus-logs) to verify there are no errors during remote write.

You can also check `prometheus_remote_storage_.*` metrics to look for success/failure attempts.

## Common Issues

### Missing metrics - cannot see cluster in Explore

If you are not seeing metrics coming in to Sumo or/and your cluster is not showing up in
[Explore](https://help.sumologic.com/docs/observability/kubernetes/monitoring#open-explore) it is most likely due to the fact that
Prometheus pod is not running.

One can verify that by using the following command:

```
$ kubectl get pod -n <NAMESPACE> -l app.kubernetes.io/name=prometheus
NAME                                 READY   STATUS    RESTARTS   AGE
prometheus-<NAMESPACE>-prometheus-0  2/2     Running   1          4d20h
```

In case it is not running one can check prometheus-operator logs for any related issues:

```
kubectl logs -n <NAMESPACE> -l app=kube-prometheus-stack-operator
```

### Pod stuck in `ContainerCreating` state

If you are seeing a pod stuck in the `ContainerCreating` state and seeing logs like

```
Warning  FailedCreatePodSandBox  29s   kubelet, ip-172-20-87-45.us-west-1.compute.internal  Failed create pod sandbox: rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

you have an unhealthy node. Killing the node should resolve this issue.

### Missing `kubelet` metrics

Navigate to the `kubelet` targets using the steps above. You may see that the targets are down with 401 errors. If so, there are two known
workarounds you can try.

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

Add the following lines to the `kube-prometheus-stack` section of your `user-values.yaml` file:

```
kube-prometheus-stack:
  ...
  kubelet:
    serviceMonitor:
      https: false
```

and upgrade the helm chart:

```
helm upgrade collection sumologic/sumologic --reuse-values --version=<RELEASE-VERSION> -f user-values.yaml
```

### Missing `kube-controller-manager` or `kube-scheduler` metrics

There’s an issue with backwards compatibility in the current version of the kube-prometheus-stack helm chart that requires us to override
the selectors for kube-scheduler and kube-controller-manager in order to see metrics from them. If you are not seeing metrics from these two
targets, you can use the following config.

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

If you are running the out of the box rancher monitoring setup, you cannot run our Prometheus operator alongside it. The Rancher Prometheus
Operator setup will actually kill and permanently terminate our Prometheus Operator instance and will prevent the metrics system from coming
up. If you have the Rancher prometheus operator setup running, they will have to use the UI to disable it before they can install our
collection process.

### Falco and Google Kubernetes Engine (GKE)

`Google Kubernetes Engine (GKE)` uses Container-Optimized OS (COS) as the default operating system for its worker node pools. COS is a
security-enhanced operating system that limits access to certain parts of the underlying OS. Because of this security constraint, Falco
cannot insert its kernel module to process events for system calls. However, COS provides the ability to use extended Berkeley Packet Filter
(eBPF) to supply the stream of system calls to the Falco engine. eBPF is currently only supported on GKE and COS. For more information see
[Falco documentation](https://falco.org/docs/getting-started/third-party/#gke).

To install on `GKE`, use the provided override file to customize your configuration and uncomment the following lines in the `values.yaml`
file referenced below:

```
  #driver:
  #  kind: ebpf
```

### Falco and OpenShift

Falco does not provide modules for all kernels. When Falco module is not available for particular kernel, Falco tries to build it. Building
a module requires `kernel-devel` package installed on nodes.

For OpenShift, installation of `kernel-devel` on nodes is provided through MachineConfig used by
[Machine Config operator](https://github.com/openshift/machine-config-operator). When update of machine configuration is needed machine is
rebooted, please see
[documentation](https://github.com/openshift/machine-config-operator/blob/master/docs/MachineConfigDaemon.md#coordinating-updates). The
process of changing nodes configuration may require long time during which Pods scheduled on unchanged nodes are in `Init` state.

Node configuration can be verified by following annotations:

- `machineconfiguration.openshift.io/currentConfig`
- `machineconfiguration.openshift.io/desiredConfig`
- `machineconfiguration.openshift.io/state`

After that, please remove Otelcol pods and associated PVC-s.

For example, if the namespace where the collection is installed is `collection`, run the following set of commands:

```bash
NAMESPACE_NAME=collection

for POD_NAME in $(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep otelcol-logs); do
  kubectl -n ${NAMESPACE_NAME} delete pvc "buffer-${POD_NAME}" &
  kubectl -n ${NAMESPACE_NAME} delete pod ${POD_NAME}
  kubectl -n ${NAMESPACE_NAME} delete pod ${POD_NAME}
done
```

The duplicated pod deletion command is there to make sure the pod is not stuck in `Pending` state with event
`persistentvolumeclaim "file-storage-sumologic-otelcol-logs-1" not found`.

### Out of memory (OOM) failures for Prometheus Pod

If you observe that Prometheus Pod needs more and more resources (out of memory failures - OOM killed Prometheus) and you are not able to
increase them then you may need to horizontally scale Prometheus. :construction: Add link to Prometheus sharding doc here.

### Prometheus: server returned HTTP status 404 Not Found: 404 page not found

If you see the following error in Prometheus logs:

```text
ts=2023-01-30T16:39:27.436Z caller=dedupe.go:112 component=remote level=error remote_name=2b2fa9 url=http://sumologic-sumologic-remote-write-proxy.sumologic.svc.cluster.local:9888/prometheus.metrics.kubelet msg="non-recoverable error" count=194 exemplarCount=0 err="server returned HTTP status 404 Not Found: 404 page not found"
```

please change the following configurations:

- `kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite`
- `kube-prometheus-stack.prometheus.prometheusSpec.additionalRemoteWrite`

so `url` start with `http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888`.

Please see the following example:

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      remoteWrite:
        - url: http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888/prometheus.metrics.state
          ...
```

Alternatively you can add `/prometheus.metrics.kubelet` to `metadata.metrics.config.additionalEndpoints`

Please see the following example:

```yaml
metadata:
  metrics:
    config:
      additionalEndpoints:
        - /prometheus.metrics.kubelet
```

### OpenTelemetry: dial tcp: lookup collection-sumologic-metadata-logs.sumologic.svc.cluster.local.: device or resource busy

If you see the following error in OpenTelemetry Pods:

```yaml
2023-01-31T14:50:20.263Z        info    exporterhelper/queued_retry.go:426      Exporting failed. Will retry the request after interval.        {"kind": "exporter", "data_type": "logs", "name": "otlphttp", "error": "failed to make an HTTP request: Post \"http://collection-sumologic-metadata-logs.sumologic.svc.cluster.local.:4318/v1/logs\": dial tcp: lookup collection-sumologic-metadata-logs.sumologic.svc.cluster.local.: device or resource busy", "interval": "16.601790675s"}
```

Add the following environment variable to the affected Statefulset/Daemonset/Deployment:

```yaml
extraEnvVars:
  - name: GODEBUG
    value: netdns=go
```

For example for OpenTelemetry Logs Collector:

```yaml
otellogs:
  daemonset:
    extraEnvVars:
      - name: GODEBUG
        value: netdns=go
```
