# How to install if you have standalone Prometheus

Update your Prometheus configuration file’s `remote_write` section, as per the documentation [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write), by taking the `remoteWrite` section of the `prometheus-overrides.yaml` file, and making the following changes:

* `writeRelabelConfigs:` change to `write_relabel_configs:`
* `sourceLabels:` change to `source_labels:`
*  Modify remote urls in the `remoteWrite` section of the `prometheus-overrides.yaml` file

The urls in `remoteWrite` section of the `prometheus-overrides.yaml` file uses `env` variables which need to be changed to point it to the correct location.

- Replace `$(CHART)` with the `release name-namespace` that you have used while installing the sumologic helm chart.
- Replace `$(NAMESPACE)` with the namespace where prometheus is running.

For eg:
If you have installed the sumlogic helm chart with release name `collection` in `sumologic` namespace and the prometheus is running in `prometheus` namespace:
```
`$(CHART).$(NAMESPACE)` will be replaced by `collection-sumologic.prometheus`
```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)