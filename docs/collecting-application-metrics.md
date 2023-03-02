# Collecting Application Metrics

This document covers multiple different use cases related to scraping custom application metrics exposed in Prometheus format.

There are two major sections:

- [Scraping metrics](#scraping-metrics) which describes how to send your application metrics to sumo
- [Metrics modifications](#metrics-modifications) which describes how to filter metrics and rename both metrics and metric metadata

## Scraping metrics

This section describes how to scrape metrics from your applications. Several scenarios has been covered:

- [Application metrics are exposed (one endpoint scenario)](#application-metrics-are-exposed-one-endpoint-scenario)
- [Application metrics are exposed (multiple enpoints scenario)](#application-metrics-are-exposed-multiple-enpoints-scenario)
- [Application metrics are not exposed](#application-metrics-are-not-exposed)

### Application metrics are exposed (one endpoint scenario)

If there is only one endpoint in the Pod you want to scrape metrics from, you can use annotations. Add the following annotations to your Pod
definition:

```yaml
# ...
annotations:
  prometheus.io/port: 8000 # Port which metrics should be scraped from
  prometheus.io/scrape: true # Set if metrics should be scraped from this Pod
  prometheus.io/path: "/metrics" # Path which metrics should be scraped from
```

**NOTE:** If you add more than one annotation with the same name, only the last one will be used.

### Application metrics are exposed (multiple enpoints scenario)

If you want to scrape metrics from multiple endpoints in a single Pod, you need a Service which points to the Pod and also to configure
`kube-prometheus-stack.prometheus.additionalServiceMonitors` in your `user-values.yaml`:

```yaml
kube-prometheus-stack:
  prometheus:
    additionalServiceMonitors:
      - name: <service monitor name>
        endpoints:
          - port: "<port name or number>"
            path: <metrics path>
            relabelings:
              ## Sets _sumo_forward_ label to true
              - sourceLabels: [__name__]
                separator: ;
                regex: (.*)
                targetLabel: _sumo_forward_
                replacement: "true"
                action: replace
        namespaceSelector:
          matchNames:
            - <namespace>
        selector:
          matchLabels:
            <identyfing label 1>: <value of indentyfing label 1>
            <label2>: <value of identyfing label 2>
```

**Note** For advanced serviceMonitor configuration, please look at the [Prometheus documentation][prometheus_service_monitors]

> **Note** If you not set `_sumo_forward_` label you will have to configure `additionalRemoteWrite`:
>
> ```yaml
> kube-prometheus-stack:
>   prometheus:
>     prometheusSpec:
>       additionalRemoteWrite:
>         ## This is required to keep default configuration. It's copy of values.yaml content
>         - url: http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888/prometheus.metrics.applications.custom
>           remoteTimeout: 5s
>           writeRelabelConfigs:
>             - action: keep
>               regex: ^true$
>               sourceLabels: [_sumo_forward_]
>             - action: labeldrop
>               regex: _sumo_forward_
>         ## This is your custom remoteWrite configuration
>         - url: http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888/prometheus.metrics.<custom endpoint name>
>           writeRelabelConfigs:
>             - action: keep
>               regex: <metric1>|<metric2>|...
>               sourceLabels: [__name__]
> ```
>
> We recommend using a regex validator, for example [https://regex101.com/]

[prometheus_service_monitors]:
  https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.ServiceMonitor
[https://regex101.com/]: https://regex101.com/

#### Example

Let's consider a Pod which exposes the following metrics:

```txt
my_metric_cpu
my_metric_memory
```

on the following endpoints:

```txt
:3000/metrics
:3001/custom-endpoint
```

The Pod's definition looks like the following:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: my-custom-app
  name: my-custom-app-56fdc95c9c-r5pvc
  namespace: my-custom-app-namespace
  # ...
spec:
  containers:
    - ports:
        - containerPort: 3000
          protocol: TCP
        - containerPort: 3001
          protocol: TCP
  # ...
```

There is also a Service which exposes Pod ports:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-custom-app-service
  managedFields:
  name: my-custom-app-service
  namespace: my-custom-app-namespace
spec:
  ports:
    - name: "some-port"
      port: 3000
      protocol: TCP
      targetPort: 3000
    - name: "another-port"
      port: 3001
      protocol: TCP
      targetPort: 3001
  selector:
    app: my-custom-app
```

In order to scrape metrics from the above objects, the following configuration should be applied to `user-values.yaml`:

```yaml
kube-prometheus-stack:
  prometheus:
    additionalServiceMonitors:
      - name: my-custom-app-service-monitor
        endpoints:
          - port: some-port
            path: /metrics
            relabelings:
              ## Sets _sumo_forward_ label to true
              - sourceLabels: [__name__]
                separator: ;
                regex: (.*)
                targetLabel: _sumo_forward_
                replacement: "true"
                action: replace
          - port: another-port
            path: /custom-endpoint
            relabelings:
              ## Sets _sumo_forward_ label to true
              - sourceLabels: [__name__]
                separator: ;
                regex: (.*)
                targetLabel: _sumo_forward_
                replacement: "true"
                action: replace
        namespaceSelector:
          matchNames:
            - my-custom-app-namespace
        selector:
          matchLabels:
            app: my-custom-app-service
```

### Application metrics are not exposed

In case you want to scrape metrics from application which do not expose them, you can use telegraf operator. It will scrape metrics
according to configuration and expose them on port `9273` so Prometheus will be able to scrape them.

For example to expose metrics from nginx Pod, you can use the following annotations:

```
annotations:
  telegraf.influxdata.com/inputs: |+
  [[inputs.nginx]]
  urls = ["http://localhost/nginx_status"]
  telegraf.influxdata.com/class: sumologic-prometheus
  telegraf.influxdata.com/limits-cpu: '750m'
```

`sumologic-prometheus` defines the way telegraf operator will expose the metrics. They are going to be exposed in prometheus format on port
`9273` and `/metrics` path.

**NOTE** If you apply annotations on Pod which is subject of other object, e.g. DaemonSet, it won't take affect. In such case, the
annotation should be added to Pod specification in DeamonSet template.

After restart, the Pod should have additional `telegraf` container.

To scrape and forward exposed metrics to Sumo Logic, please follow one of the following scenarios:

- [Application metrics are exposed (one endpoint scenario)](#application-metrics-are-exposed-one-endpoint-scenario)
- [Application metrics are exposed (multiple enpoints scenario)](#application-metrics-are-exposed-multiple-enpoints-scenario)

## Metrics modifications

This section coverts the following metrics modifications:

- [Filtering metrics](#filtering-metrics)
- [Renaming metric](#renaming-metric)
- [Adding or renaming metadata](#adding-or-renaming-metadata)

### Filtering metrics

In order to filter in or out the metrics, you can add [filterprocessor] to metric's extraProcessors. Please see the following example:

```yaml
sumologic:
  metrics:
    otelcol:
      extraProcessors:
        - filter/1:
            metrics:
              ## Definition of inclusion
              include:
                ## Match type, can be regexp or strict
                match_type: regexp
                ## metric names to match for inclusion
                metric_names:
                  - prefix/.*
                  - prefix_.*
                ## Metadata to match for inclusion
                resource_attributes:
                  - key: container.name
                    value: app_container_1
              ## Definition of exclusion
              exclude:
                ## Match type, can be regexp or strict
                match_type
                ## Metric names for exclusion
                metric_names:
                  - hello_world
                  - hello/world
                ## Metadata to match for exclusion
                resource_attributes:
                  - key: container.name
                    value: app_container_7
```

[filterprocessor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/filterprocessor

#### Default attributes

By default, the following attributes should be available:

| Attribute name          | Description                                                |
| ----------------------- | ---------------------------------------------------------- |
| \_collector             | Sumo Logic collector name                                  |
| \_origin                | Sumo Logic origin metadata ("kubernetes")                  |
| \_sourceCategory        | Sumo Logic source category                                 |
| \_sourceHost            | Sumo Logic source host                                     |
| \_sourceName            | Sumo Logic source Nmae                                     |
| cluster                 | Cluster Name                                               |
| endpoint                | Metrics endpoint                                           |
| http_listener_v2_path   | Path used to receive data from Prometheus                  |
| instance                | Pod instance                                               |
| job                     | Prometheus job name                                        |
| k8s.container.name      | Kubernetes Container name                                  |
| k8s.deployment.name     | Kubernetes Deployment name                                 |
| k8s.namespace.name      | Kubernetes Namespace name                                  |
| k8s.node.name           | Kubernetes Node name                                       |
| k8s.pod.name            | Kubernetes Pod name                                        |
| k8s.pod.pod_name        | Kubernetes Pod name                                        |
| k8s.replicaset.name     | Kubernetes Replicaset name                                 |
| k8s.service.name        | Kubernetes Service name                                    |
| k8s.statefulset.name    | Kubernetes Statefulset name                                |
| pod*labels*<label_name> | Kubernetes Pod label. Every label is a different attribute |
| prometheus              | Prometheus                                                 |
| prometheus_replica      | Prometheus Replica name                                    |
| prometheus_service      | Prometheus Service name                                    |

**NOTE** Before ingestion to Sumo Logic, attributes are renamed according to the [sumologicschemaprocessor documentation][sumologicschema]

[sumologicschema]:
  https://github.com/SumoLogic/sumologic-otel-collector/tree/main/pkg/processor/sumologicschemaprocessor#attribute-translation

### Renaming metric

In order to rename metrics, the [transformprocessor] can be use. Please look at the following snippet:

```yaml
sumologic:
  metrics:
    otelcol:
      extraProcessors:
        - transform/1:
            metric_statements:
              - context: metric
                statements:
                  ## Renames <old_name> to <new_name>
                  - set(name, "<new_name>") where name == "<old_name>"
```

### Adding or renaming metadata

If you want to add or rename metadata, the [transformprocessor] can be use. Please look at the following snippet:

```yaml
sumologic:
  metrics:
    otelcol:
      extraProcessors:
        - transform/1:
            metric_statements:
              - context: resource
                statements:
                  ## adds <new_name> metadata
                  - set(attributes["<new_name>"], attributes["<old_name>"])
                  ## adds <new_static_name> metadata
                  - set(attributes["<new_static_name>"], "<static_value>")
                  ## removes <old_name> metadata
                  - delete_key(attributes, "<old_name>")
```

**Note:** See [Default attributes](#default-attributes) for more information about attributes.

[transformprocessor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/transformprocessor

## Investigation

If you do not see your metrics in Sumo Logic, please check the following stages:

- [Check if metrics are in Prometheus](#check-if-metrics-are-in-prometheus)

  - [Investigate Prometheus scrape configuration](#investigate-prometheus-scrape-configuration)
  - [Pod is visible in Prometheus targets](#pod-is-visible-in-prometheus-targets)
  - [There is no target for serviceMonitor](#there-is-no-target-for-servicemonitor)
  - [Pod is not visible in target for custom serviceMonitor](#pod-is-not-visible-in-target-for-custom-servicemonitor)

- [Check if Prometheus knows how to send metrics to Sumo Logic](#check-if-prometheus-knows-how-to-send-metrics-to-sumo-logic)

### Check if metrics are in Prometheus

First of all, you need to expose Prometheus UI locally. You need to find Prometheus UI service name:

```console
$ export NAMESPACE=sumologic
$ kubectl -n "${NAMESPACE}" get service
NAME                                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                                      AGE
collection-sumologic-otelcol-events-headless    ClusterIP   None             <none>        24231/TCP,8888/TCP                                                                                                           3d14h
collection-sumologic-otelcol-logs-headless      ClusterIP   None             <none>        4318/TCP,24321/TCP,24231/TCP                                                                                                 3d14h
collection-sumologic-otelcol-metrics-headless   ClusterIP   None             <none>        9888/TCP,24231/TCP                                                                                                           3d14h
collection-sumologic-traces-sampler-headless    ClusterIP   None             <none>        1777/TCP,8888/TCP,4317/TCP,4318/TCP                                                                                          3d14h
collection-sumologic-remote-write-proxy         ClusterIP   10.152.183.203   <none>        9888/TCP                                                                                                                     3d14h
collection-kube-state-metrics                   ClusterIP   10.152.183.196   <none>        8080/TCP                                                                                                                     3d14h
collection-grafana                              ClusterIP   10.152.183.150   <none>        80/TCP                                                                                                                       3d14h
collection-prometheus-node-exporter             ClusterIP   10.152.183.238   <none>        9100/TCP                                                                                                                     3d14h
collection-kube-prometheus-operator             ClusterIP   10.152.183.214   <none>        8080/TCP                                                                                                                     3d14h
collection-kube-prometheus-prometheus           ClusterIP   10.152.183.130   <none>        9090/TCP                                                                                                                     3d14h
collection-sumologic-otelcol-events             ClusterIP   10.152.183.215   <none>        24231/TCP,8888/TCP                                                                                                           3d14h
collection-sumologic-traces-gateway             ClusterIP   10.152.183.138   <none>        1777/TCP,8888/TCP,4317/TCP,4318/TCP                                                                                          3d14h
collection-telegraf-operator                    ClusterIP   10.152.183.192   <none>        443/TCP                                                                                                                      3d14h
collection-sumologic-metadata-metrics           ClusterIP   10.152.183.133   <none>        9888/TCP,8888/TCP                                                                                                            3d14h
collection-sumologic-otelcol                    ClusterIP   10.152.183.120   <none>        5778/TCP,6831/UDP,6832/UDP,8888/TCP,9411/TCP,14250/TCP,14267/TCP,14268/TCP,55678/TCP,4317/TCP,4318/TCP,55680/TCP,55681/TCP   3d14h
collection-sumologic-metadata-logs              ClusterIP   10.152.183.16    <none>        4318/TCP,24321/TCP,8888/TCP                                                                                                  3d14h
collection-sumologic-otelcol-logs-collector     ClusterIP   10.152.183.36    <none>        8888/TCP                                                                                                                     3d14h
collection-sumologic-otelagent                  ClusterIP   10.152.183.141   <none>        5778/TCP,6831/UDP,6832/UDP,8888/TCP,9411/TCP,14250/TCP,14267/TCP,14268/TCP,55678/TCP,4317/TCP,4318/TCP,55680/TCP,55681/TCP   3d14h
prometheus-operated                             ClusterIP   None             <none>        9090/TCP                                                                                                                     3d14h
```

In our example, the service is named `collection-kube-prometheus-prometheus`. You should look for `kube-prometheus-prometheus` phrase or it
part and the service exposes on `9090/TCP`.

Next, please run the following command to expose prometheus on `0.0.0.0:8000`.

```console
$ export SERVICE=collection-kube-prometheus-prometheus
$ kubectl port-forward -n "${NAMESPACE}" service/${SERVICE} --address=0.0.0.0 8000:9090
Forwarding from 0.0.0.0:8000 -> 9090
```

Now, you can access the Prometheus UI via `http://localhost:8000`:

![Prometheus UI](/images/metrics/prometheus-ui.png)

Type the metric name in the search bar and run `Execute`:

![Prometheus query results](/images/metrics/prometheus-query.png)

If the metrics have been found, you can go to the
[Check if Prometheus knows how to send metrics to Sumo Logic](#check-if-prometheus-knows-how-to-send-metrics-to-sumo-logic) section.
Otherwise, please check [Investigate Prometheus scrape configuration](#investigate-prometheus-scrape-configuration) section.

#### Investigate Prometheus scrape configuration

We assume, that you have exposed Prometheus on `localhost:8000` like in
[Check if metrics are in Prometheus](#check-if-metrics-are-in-prometheus) section.

Go to the `http://localhost:8000/targets?search=` and search for the pod you want to scrape metrics from. It should be under the
`kubernetes-pods` target name if you are using annotations, otherwise, it should be under serviceMonitor name you defined in configuration.

##### Pod is visible in Prometheus targets

For example, our pod is under `kubernetes-pods` section. As we can see something is wrong, and Prometheus cannot read the metrics:

![Prometheus targets without error](/images/metrics/prometheus-targets-error.png)

In the `Error` column we can see the reason of that, which is:

```txt
Get "http://10.1.126.138:3004/metrics": dial tcp 10.1.126.138:3004: connect: connection refused
```

In that example, we need to check why the endpoint is not accessible, and after looking at the Pod definition, we see that metrics are
exposed on port `3000`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-pod
  namespace: app-pod
  labels:
    app: app-pod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-pod
  template:
    metadata:
      labels:
        service: app-pod
        app: app-pod
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3004"
    spec:
      containers:
        - ports:
            - containerPort: 3000
# ...
```

To fix that, we need to change `prometheus.io/port: "3004"` to `prometheus.io/port: "3000"`, and redeploy the application.

After fix, we can see that Prometheus can read metrics from the Pod now:

![Prometheus targets without error](/images/metrics/prometheus-targets-ok.png)

**NOTE** This example was simple as it was just simple misconfiguration. There can be much complicated cases, eg. Prometheus cannot
authenticate to the metrics endpoints, or cannot access it due to network configuration.

If you cannot spot your Pod in Prometheus targets and you are using annotations, please ensure that deployed Pod has them in the
definitions.

If you are using serviceMonitor, please go to the [There is no target for serviceMonitor](#there-is-no-target-for-servicemonitor) or
[Pod is not visible in target for custom serviceMonitor](#pod-is-not-visible-in-target-for-custom-servicemonitor)

##### There is no target for serviceMonitor

If you created your own serviceMonitor using `additionalServiceMonitors` configuration and you cannot see it in the target, please contact
with our Customer Support, or create an issue.

If you crafted it by hand, please verify that it fulfills the Proemetheus serviceMonitor selector configuration:

```console
$ kubectl -n "${NAMESPACE}" describe prometheus
...
  Service Monitor Namespace Selector:
  Service Monitor Selector:
    Match Labels:
      Release:      collection
...
```

`Service Monitor Namespace Selector` defines which namespaces are observed by Prometheus. Empty value means all namespaces
`Service Monitor Selector` defines what labels should the serviceMonitor have.

##### Pod is not visible in target for custom serviceMonitor

If you don't see Pod you are expecting to see for your serviceMonitor, but serviceMonitor is in the Prometheus targets, please verify if
`selector` and `namespaceSelector` in `additionalServiceMonitors` configuration are matching your Pod's namespace and labels.

### Check if Prometheus knows how to send metrics to Sumo Logic

If metrics are visible in Prometheus, but you cannot see them in Sumo Logic, please check if Prometheus knows how to send it to Sumo Logic
Metatada StatefulSet.

Go to the [http://localhost:8000/config](http://localhost:8000/config) and verify if your metric definition is added to any `remote_write`
section. It most likely will be covered by:

```yaml
- url: http://collection-sumologic-remote-write-proxy.sumologic.svc.cluster.local.:9888/prometheus.metrics.applications.custom
  remote_timeout: 5s
  write_relabel_configs:
    - source_labels: [_sumo_forward_]
      separator: ;
      regex: ^true$
      replacement: $1
      action: keep
    - separator: ;
      regex: _sumo_forward_
      replacement: $1
      action: labeldrop
```

If there is no `remote_write` for your metric definition, you can add one using `additionalRemoteWrite` what has been described in
[Application metrics are exposed (multiple enpoints scenario)](#application-metrics-are-exposed-multiple-enpoints-scenario) section.

However if you can see `remote_write` which matches your metrics and metrics are in Prometheus, we recommend to look at the Prometheus,
Prometheus Operator and OpenTelemetry Metrics Collector Pod logs.

If the issue won't be solved, please create an issue or contact with our Customer Support.
