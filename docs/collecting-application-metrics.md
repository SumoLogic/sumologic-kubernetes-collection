# Collecting application metrics

This document covers multiple different use cases related to scraping custom application metrics.

## Practical scenarios

### Scraping metrics

#### Application metrics are exposed (one endpoint scenario)

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

Next, add the following configuration to your `user-values.yaml`:

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      additionalRemoteWrite:
        - url: http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888/prometheus.metrics.<custom endpoint name>
          writeRelabelConfigs:
          - action: keep
            regex: <metric1>|<metric2>|...
            sourceLabels: [__name__]
```

**Note:** We recommend to use regex validator, for example [https://regex101.com/].

#### Application metrics are exposed (multiple enpoints scenario)

If you want to scrape metrics from multiple endpoints in a single Pod,
you need a Service which points to the Pod and also to configure `kube-prometheus-stack.prometheus.additionalServiceMonitors`
in your `user-values.yaml`:

```yaml
kube-prometheus-stack:
  prometheus:
    additionalServiceMonitors:
      - name: <service monitor name>
        endpoints:
          - port: <port name or number>
            path: <metrics path>
        namespaceSelector:
          matchNames:
            - <namespace>
        selector:
          matchLabels:
            <identyfing label 1>: <value of indentyfing label 1>
            <label2>: <value of identyfing label 2>
```

**Note** For advanced serviceMonitor configuration, please look at the [Prometheus documentation][prometheus_service_monitors]

At the end, you need to add the following configuration to your `user-values.yaml`,
to instruct Prometheus which metrics should be forwarded through the pipeline.

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      additionalRemoteWrite:
        - url: http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888/prometheus.metrics.<custom endpoint name>
          writeRelabelConfigs:
          - action: keep
            regex: <metric1>|<metric2>|...
            sourceLabels: [__name__]
```

**Note:** We recommend using a regex validator, for example [https://regex101.com/]

[prometheus_service_monitors]: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.ServiceMonitor
[https://regex101.com/]: https://regex101.com/

##### Example

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
          - port: another-port
            path: /custom-endpoint
        namespaceSelector:
          matchNames:
            - my-custom-app-namespace
        selector:
          matchLabels:
            app: my-custom-app-service
    prometheusSpec:
      additionalRemoteWrite:
        - url: http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888/prometheus.metrics.my_custom_metrics
          writeRelabelConfigs:
          - action: keep
            regex: my_metric_*
            sourceLabels: [__name__]
```

#### Application metrics are not exposed

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
