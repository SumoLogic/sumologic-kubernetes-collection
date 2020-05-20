# How to install if you have standalone Prometheus

__NOTE__: The Sumo Logic Kubernetes collection process does not support collecting metrics from scaling Prometheus replicas. If you are running multiple Prometheus replicas, please follow our [Side-by-Side](SideBySidePrometheus.md) instructions.

1. Download the Prometheus Operator `prometheus-overrides.yaml` by running

```bash
$ curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v1.0/deploy/helm/prometheus-overrides.yaml
```

2. Make the following modifications to the `remoteWrite` section of the `prometheus-overrides.yaml` file:

* `writeRelabelConfigs:` change to `write_relabel_configs:`
* `sourceLabels:` change to `source_labels:`
*  Modify remote URLs in the `remoteWrite` section of the `prometheus-overrides.yaml` file

The URLs in `remoteWrite` section of the `prometheus-overrides.yaml` file uses `env` variables which need to be changed to point to the correct location.

- Replace `$(CHART)` with the `release name-namespace` that you have used while installing the Sumo Logic helm chart.
- Replace `$(NAMESPACE)` with the namespace where Prometheus is running.

For example:\
If you have installed the Sumo Logic helm chart with release name `collection` in the `sumologic` namespace and Prometheus is running in the `prometheus` namespace:
```
`$(CHART).$(NAMESPACE)` will be replaced by `collection-sumologic.prometheus`
```
3. Copy the modified `remoteWrite` section of the `prometheus-overrides.yaml` file to your Prometheus configuration file’s `remote_write` section, as per the documentation [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)

4. Run the following command to find the existing Prometheus pod.
```
kubectl get pods | grep prometheus
```
5. Delete the existing Prometheus pod so that Kubernetes will respawn it with the updated configuration.
```
kubectl delete pods <prometheus_pod_name>

```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)
