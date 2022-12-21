# Collecting application metrics

This document is going to cover multiple different use cases related to scraping custom application metrics.

## Practical scenarios

### Application metrics are exposed (one endpoint scenario)

If there is only one endpoint in the pod you want to scrape metrics from, you can use annotations.
Add the following annotations to your pod definition:

```yaml
# ...
annotations:
  prometheus.io/port: 8000 # Port which metrics should be scraped from
  prometheus.io/scrape: true # Set if metrics should be scraped from this pod
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

### Application metrics are exposed (multiple enpoints scenario)

If you want to scrape metrics from multiple endpoints in a single Pod,
you need a service which points to the pod and also to configure `kube-prometheus-stack.prometheus.additionalServiceMonitors`
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

**Note:** We recommend to use regex validator, for example [https://regex101.com/]

[prometheus_service_monitors]: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.ServiceMonitor
[https://regex101.com/]: https://regex101.com/

#### Example

Let's consider a pod which exposes the following metrics:

```txt
my_metric_cpu
my_metric_memory
```

on the following endpoints:

```txt
:3000/metrics
:3001/custom-endpoint
```

The pod's definition looks like the following:

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

There is also a service which exposes pod ports:

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
