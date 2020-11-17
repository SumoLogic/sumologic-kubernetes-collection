# Deployment Guide

This page has instructions for collecting Kubernetes logs, metrics, and events;
enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic.
See our [documentation guide](https://help.sumologic.com/Solutions/Kubernetes_Solution)
for details on our Kubernetes Solution.

- [Deployment Guide](#deployment-guide)
  - [Solution overview](#solution-overview)
  - [Minimum Requirements](#minimum-requirements)
  - [Support Matrix](#support-matrix)
  - [Installation with Helm](./docs/Installation_with_Helm.md)
  - [Non Helm Installation](./docs/Non_Helm_Installation.md)
  - [Adding Additional FluentD Plugins](./docs/Additional_Fluentd_Plugins.md)
  - [Advanced Configuration/Best Practices](./docs/Best_Practices.md)
  - [Authenticating with docker registry](./docs/Authenticating_with_docker_registry.md)
  - [Alpha Releases](./docs/Alpha_Release_Guide.md)
  - [Upgrade from v0.17 to v1.0](./docs/v1_migration_doc.md)
- [Migration Steps](./docs/Migration_Steps.md)
- [Troubleshooting Collection](./docs/Troubleshoot_Collection.md)
- [Monitoring the Monitoring](./docs/monitoring-lag.md)

## Solution overview

The diagram below illustrates the components of the Kubernetes collection solution.

![solution](/images/k8s_collection_diagram.png)

- **K8S API Server**. Exposes API server metrics.
- **Scheduler.** Makes Scheduler metrics available on an HTTP metrics port.
- **Controller Manager.** Makes Controller Manager metrics available on an HTTP metrics port.
- **node-exporter.** The `node_exporter` add-on exposes node metrics, including CPU,
  memory, disk, and network utilization.
- **kube-state-metrics.** Listens to the Kubernetes API server; generates metrics
  about the state of the deployments, nodes, and pods in the cluster; and exports
  the metrics as plaintext on an HTTP endpoint listen port.
- **Prometheus deployment.** Scrapes the metrics exposed by the `node-exporter`
  add-on for Kubernetes and the `kube-state-metrics` component; writes metrics
  to a port on the Fluentd deployment.
- **Fluentd deployment.** Forwards logs and metrics to HTTP sources on a hosted collector.
  Includes multiple Fluentd plugins that parse and format the metrics and enrich them with metadata.
- **Events Fluentd deployment.** Forwards events to an HTTP source on a hosted collector.

## Minimum Requirements

Name | Version
-------- | -----
K8s | 1.10+
Helm | 3.4+

## Support Matrix

The following table displays the tested Kubernetes and Helm versions.

Name | Version
-------- | -----
K8s with EKS | 1.14<br/>1.15<br/>1.16<br/>1.17
K8s with Kops | 1.16<br/>1.17<br/>1.18
K8s with GKE | 1.15<br/>1.16
K8s with AKS | 1.16<br/>1.17
Helm | 3.4.0 (Linux)
kubectl | 1.15.0

The following matrix displays the tested package versions for our Helm chart.

Sumo Logic Helm Chart | kube-prometheus-stack/Prometheus Operator | FluentD | Fluent Bit | Falco  | Metrics Server | Telegraf Operator
|:-------- |:-------- |:-------- |:-------- |:-------- |:-------- |:--------
1.3.0 - Latest | 9.3.4 | 1.11.1 | 2.10.1 | 1.4.0 | 2.11.2 | 1.1.4
1.2.0 - 1.2.3 | 8.13.8 | 1.11.1 | 2.8.14 | 1.1.8 | 2.11.1 | -
1.1.0 | 8.13.8 | 1.8.1 | 2.8.14 | 1.1.8 | 2.11.1 | -
1.0.0 | 8.2.0 | 1.8.1 | 2.8.1 | 1.1.6 | 2.7.0 | -
0.17.0 - 0.17.4 | 8.2.0 | 1.6.3 | 2.8.1 | 1.1.0 | 2.7.0 | -
0.14.0 - 0.16.0 | 8.2.0 | 1.6.3 | 2.8.1 | 1.1.1 | 2.7.0 | -
0.13.0 | 8.2.0 | 1.6.3 | 2.8.1 | 1.0.11 | 2.7.0 | -
0.12.0 | 8.2.0 | 1.6.3 | 2.8.1 | 1.0.9  |  - | -
0.9.0 - 0.11.0 | 6.2.1 | 1.6.3 | 2.4.4 | 1.0.8   |  - | -
0.6.0 - 0.8.0 | 6.2.1 | 1.6.3 | 2.4.4 | 1.0.5    |  - | -
