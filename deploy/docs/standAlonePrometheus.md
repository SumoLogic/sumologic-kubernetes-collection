# How to install if you have standalone Prometheus

Update your Prometheus configuration file’s `remote_write` section, as per the documentation [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write), by taking the `remoteWrite` section of the `prometheus-overrides.yaml` file, and making the following changes:

* `writeRelabelConfigs:` change to `write_relabel_configs:`
* `sourceLabels:` change to `source_labels:`
