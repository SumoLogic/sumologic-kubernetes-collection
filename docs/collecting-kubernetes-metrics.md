# Collecting Kubernetes Metrics

By default, we collect selected metrics from the following Kubernetes components:

- `Kube API Server` configured with `kube-prometheus-stack.kubeApiServer.serviceMonitor`
- `Kubelet` configured with `kube-prometheus-stack.kubelet.serviceMonitor`
- `Kube Controller Manager` configured with `kube-prometheus-stack.kubeControllerManager.serviceMonitor`
- `CoreDNS` configured with `kube-prometheus-stack.coreDns.serviceMonitor`
- `Kube EtcD` configured with `kube-prometheus-stack.kubeEtcd.serviceMonitor`
- `Kube Scheduler` configured with `kube-prometheus-stack.kubeScheduler.serviceMonitor`
- `Kube State Metrics` configured with `kube-prometheus-stack.kube-state-metrics.prometheus.monitor`
- `Prometheus Node Exporter` configured with `kube-prometheus-stack.prometheus-node-exporter.prometheus.monitor`

If you want to forward additional metric from one of these services, you need to edit the corresponding Service Monitor definition. Service
Monitor tells Prometheus which metrics it should take from the service.

## Example

Let's consider the following example:

In addition to all metrics we send by default from CAdvisor you also want to forward `container_blkio_device_usage_total`.

You need to modify `kube-prometheus-stack.kubelet.serviceMonitor.cAdvisorMetricRelabelings` to include `container_blkio_device_usage_total`.

```yaml
kube-prometheus-stack:
  kubelet:
    serviceMonitor:
      cAdvisorMetricRelabelings:
        - action: keep
          regex: (?:container_blkio_device_usage_total|container_cpu_usage_seconds_total|container_memory_working_set_bytes|container_fs_usage_bytes|container_fs_limit_bytes|container_cpu_cfs_throttled_seconds_total|container_network_receive_bytes_total|container_network_transmit_bytes_total)
          sourceLabels: [__name__]
        - action: labelmap
          regex: container_name
          replacement: container
        - action: drop
          sourceLabels: [container]
          regex: POD
        - action: labeldrop
          regex: (id|name)
```

**Note:** You can use the method described in
[Troubleshooting Collection document](https://help.sumologic.com/docs/send-data/kubernetes/troubleshoot-collection#check-the-metrics-endpoint-for-kubernetes-services)
to troubleshoot this process.

## Metrics modifications

See the relevant section in [Collecting application metrics](/docs/collecting-application-metrics.md#metrics-modifications).

## Investigation

For investigation you may want to look at the
[Collecting application metrics](/docs/collecting-application-metrics.md#metrics-modifications) and
[Troubleshooting Collection document](https://help.sumologic.com/docs/send-data/kubernetes/troubleshoot-collection#collecting-metrics)
