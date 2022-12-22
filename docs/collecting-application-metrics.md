# Collecting application metrics

This document covers multiple different use cases related to scraping custom application metrics exposed in Prometheus format.

There are two major sections:

- [Scraping metrics](#scraping-metrics) which describes how to send your application metrics to sumo
- [Metrics modifications](#metrics-modifications)
  which describes how to filter metrics and rename both metrics and metric metadata

## Scraping metrics

This section describes how to scrape metrics from your applications.
Several scenarios has been covered:

- [Application metrics are exposed (one endpoint scenario)](#application-metrics-are-exposed-one-endpoint-scenario)
- [Application metrics are exposed (multiple enpoints scenario)](#application-metrics-are-exposed-multiple-enpoints-scenario)
- [Application metrics are not exposed](#application-metrics-are-not-exposed)

### Application metrics are exposed (one endpoint scenario)

If there is only one endpoint in the Pod you want to scrape metrics from, you can use annotations.
Add the following annotations to your Pod definition:

```yaml
# ...
annotations:
  prometheus.io/port: 8000 # Port which metrics should be scraped from
  prometheus.io/scrape: true # Set if metrics should be scraped from this Pod
  prometheus.io/path: "/metrics" # Path which metrics should be scraped from
```

**NOTE:** If you add more than one annotation with the same name, only the last one will be used.

### Application metrics are exposed (multiple enpoints scenario)

If you want to scrape metrics from multiple endpoints in a single Pod,
you need a Service which points to the Pod and also to configure `kube-prometheus-stack.prometheus.additionalServiceMonitors`
in your `user-values.yaml`:

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
>           - action: keep
>             regex: <metric1>|<metric2>|...
>             sourceLabels: [__name__]
> ```
>
> We recommend using a regex validator, for example [https://regex101.com/]

[prometheus_service_monitors]: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.ServiceMonitor
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

In case you want to scrape metrics from application which do not expose them, you can use telegraf operator.
It will scrape metrics according to configuration and expose them on port `9273` so Prometheus will be able to scrape them.

For example to expose metrics from nginx Pod, you can use the following annotations:

```
annotations:
  telegraf.influxdata.com/inputs: |+
  [[inputs.nginx]]
  urls = ["http://localhost/nginx_status"]
  telegraf.influxdata.com/class: sumologic-prometheus
  telegraf.influxdata.com/limits-cpu: '750m'
```

`sumologic-prometheus` defines the way telegraf operator will expose the metrics.
They are going to be exposed in prometheus format on port `9273` and `/metrics` path.

**NOTE** If you apply annotations on Pod which is subject of other object, e.g. DaemonSet, it won't take affect.
In such case, the annotation should be added to Pod specification in DeamonSet template.

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

In order to filter in or out the metrics, you can add [filterprocessor] to metric's extraProcessors.
Please see the following example:

```yaml
metadata:
  metrics:
    config:
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
                  - Key: container.name
                    Value: app_container_1
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
                  - Key: container.name
                    Value: app_container_7
```

#### Default attributes

By default, the following attributes should be available:

| Attribute name          | Description                                                |
|-------------------------|------------------------------------------------------------|
| _collector              | Sumo Logic collector name                                  |
| _origin                 | Sumo Logic origin metadata ("kubernetes")                  |
| _sourceCategory         | Sumo Logic source category                                 |
| _sourceHost             | Sumo Logic source host                                     |
| _sourceName             | Sumo Logic source Nmae                                     |
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
| pod_labels_<label_name> | Kubernetes Pod label. Every label is a different attribute |
| prometheus              | Prometheus                                                 |
| prometheus_replica      | Prometheus Replica name                                    |
| prometheus_service      | Prometheus Service name                                    |

**NOTE** Before ingestion to Sumo Logic, attributes are renamed according to the [sumologicschemaprocessor documentation][sumologicschema]

[sumologicschema]: https://github.com/SumoLogic/sumologic-otel-collector/tree/main/pkg/processor/sumologicschemaprocessor#attribute-translation

### Renaming metric

In order to rename metrics, the [transformprocessor] can be use.
Please look at the following snippet:

```yaml
metadata:
  metrics:
    config:
      extraProcessors:
        - transform/1:
            metric_statements:
              - context: metric
                statements:
                  ## Renames <old_name> to <new_name>
                  - set(name, "<new_name>") where name == "<old_name>"
```

### Adding or renaming metadata

If you want to add or rename metadata, the [transformprocessor] can be use.
Please look at the following snippet:

```yaml
metadata:
  metrics:
    config:
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
