# How to install if you have an existing Prometheus operator

<!-- TOC -->
 
- [Install Fluentd, Fluent-bit, and Falco](#install-fluentd-fluent-bit-and-falco) 
- [Overwrite Prometheus Remote Write Configuration](#overwrite-prometheus-remote-write-configuration) 
- [Merge Prometheus Remote Write Configuration](#merge-prometheus-remote-write-configuration)  

<!-- /TOC -->

## Install Fluentd, Fluent-bit, and Falco

Run the following to download the `values.yaml` file

```bash
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.15.0/deploy/helm/sumologic/values.yaml
```

Edit the `values.yaml` file to `prometheus-operator.enabled = false`, and run

```bash
helm install sumologic/sumologic --name collection --namespace sumologic -f values.yaml --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> 
```

## Overwrite Prometheus Remote Write Configuration

If you have not already customized your [remote write configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write), run the following to update the [remote write configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write) of the prometheus operator by installing with the prometheus overrides file we provide below.

```bash
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.15.0/deploy/helm/prometheus-overrides.yaml
```

Then run

```bash
helm upgrade prometheus-operator stable/prometheus-operator -f prometheus-overrides.yaml
```

## Merge Prometheus Remote Write Configuration

If you have customized your Prometheus remote write configuration, follow these steps to merge the configurations. 

Helm supports providing multiple configuration files, and priority will be given to the last (right-most) file specified. You can obtain your current prometheus configuration by running

```bash
helm get values prometheus-operator > current-values.yaml
```

Any section of `current-values.yaml` that conflicts with sections of our `prometheus-overrides.yaml` will have to be removed from the `prometheus-overrides.yaml` file and appended to `current-values.yaml` in relevant sections. For any config that doesn’t conflict, you can leave them in `prometheus-overrides.yaml`. Then run

```bash
helm upgrade prometheus-operator stable/prometheus-operator -f current-values.yaml -f prometheus-overrides.yaml
```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)
