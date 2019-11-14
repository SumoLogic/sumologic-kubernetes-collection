# How to install our Prometheus side by side with your existing Prometheus

When installing our Helm Chart it is possible to have more than one Prometheus server running in the same cluster. You can deploy our solution more than once in the same cluster or in a cluster with an existing Prometheus server. To use a different port number than the default 9100 set the following fields for the Prometheus node exporter when installing our Helm Chart. For example:

```
--set prometheus-operator.prometheus-node-exporter.service.port=9200 --set prometheus-operator.prometheus-node-exporter.service.targetPort=9200
```

Or add the following to the prometheus-operator section of your overrides values.yaml:

```
prometheus-operator:
  ...
  prometheus-node-exporter:
    service:
      port: 9200
      targetPort: 9200
  ...
```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)