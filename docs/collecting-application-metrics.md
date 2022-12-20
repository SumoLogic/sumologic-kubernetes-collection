# Collecting application metrics

This document is going to cover multiple different use cases related to scraping custom application metrics.

## Practical scenarios

### Application metrics are exposed (one endpoint scenario)

If there is only one endpoint in the pod you want to scrape metrics from, you can use annotations.
Add the following annotations to your pod definition:

```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "9273"
```

where `prometheus.io/port` points to port on which your pod metrics are available.

**NOTE:** You cannot add more than one annotation with the same name. Only the last one will be used.

Next, add the following configuration to your `user-values.yaml`:

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      additionalRemoteWrite:
        - url: http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888/prometheus.metrics.my_custom_metrics
          writeRelabelConfigs:
          - action: keep
            regex: <metric1>|<metric2>|...
            sourceLabels: [__name__]
```

**Note:** We recommend to use regex validator, for example [https://regex101.com/](https://regex101.com/)

### Application metrics are exposed (multiple enpoints scenario)

If there is more than one endpoiont you want to scrape metrics from in a pod,
you need a service which points to the pod and you need to craft and apply the `serviceMonitor` object:

```yaml
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: <service_monitor_name>
  namespace: <service_monitor_namespace>
  labels:
    release: collection # Ensure this matches the `release` label on your Prometheus pod
spec:
  selector:
    matchLabels:
      <label_key>: <label_value>
  namespaceSelector:
    matchNames:
    - <namespace>
  endpoints:
  - port: <service_port> # Same as service's port name
    interval: <interval>
```

Next, add the following configuration to your `user-values.yaml`:

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      additionalRemoteWrite:
        - url: http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888/prometheus.metrics.my_custom_metrics
          writeRelabelConfigs:
          - action: keep
            regex: <metric1>|<metric2>|...
            sourceLabels: [__name__]
```

**Note:** We recommend to use regex validator, for example [https://regex101.com/](https://regex101.com/)
