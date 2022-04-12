# Deployment Guide for unreleased version

This page has instructions for collecting Kubernetes logs, metrics, and events;
enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic.
See our [documentation guide](https://help.sumologic.com/Solutions/Kubernetes_Solution)
for details on our Kubernetes Solution.

- [Documentation versions](#documentation-versions)
- [Solution overview](#solution-overview)
- [Minimum Requirements](#minimum-requirements)
- [Support Matrix](#support-matrix)

Documentation for other versions can be found in the [main README file](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/README.md#documentation).

---

Documentation links:

- Installation
  - [Installation with Helm](./docs/Installation_with_Helm.md)
  - [Non Helm Installation](./docs/Non_Helm_Installation.md)

- Configuration
  - [Adding Additional FluentD Plugins](./docs/Additional_Fluentd_Plugins.md)
  - [Additional Prometheus configuration](./docs/additional_prometheus_configuration.md)
  - [Advanced Configuration/Best Practices](./docs/Best_Practices.md)
  - [Advanced Configuration/Security best practices](./docs/Security_Best_Practices.md)
  - [Authenticating with container registry](./docs/Working_with_container_registries.md#authenticating-with-container-registry)
    - [Using pull secrets with `sumologic-kubernetes-collection` helm chart](./docs/Working_with_container_registries.md#authenticating-with-container-registry)
  - [Container log parsing (Docker, CRI-O, containerd)](./docs/ContainerLogs.md)
  - Open Telemetry `beta`
    - [Open Telemetry with `sumologic-kubernetes-collection`](./docs/opentelemetry_collector.md)
    - [Comparison of Fluentd and Opentelemetry Collector functionality](./docs/fluentd_otc_comparison.md)

- Upgrades
  - [Upgrade from v0.17 to v1.0](./docs/v1_migration_doc.md)
  - [Upgrade from v1.3 to v2.0](./docs/v2_migration_doc.md)

- [Migration steps from `SumoLogic/fluentd-kubernetes-sumologic`](./docs/Migration_Steps.md)
- [Troubleshooting Collection](./docs/Troubleshoot_Collection.md)
- [Monitoring the Monitoring](./docs/monitoring-lag.md)
- [Performance estimates for running collection chart](./docs/Performance.md)
- [Dev Releases](./docs/Dev.md)

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

| Name | Version |
|------|---------|
| K8s  | 1.18+   |
| Helm | 3.4+    |

## Support Matrix

The following table displays the tested Kubernetes and Helm versions.

| Name          | Version                                  |
|---------------|------------------------------------------|
| K8s with EKS  | 1.18<br/>1.19<br/>1.20<br/>1.21          |
| K8s with Kops | 1.18<br/>1.19<br/>1.20<br/>1.21<br/>1.22 |
| K8s with GKE  | 1.20<br/>1.21                            |
| K8s with AKS  | 1.19<br/>1.20<br/>1.21<br/>1.22          |
| OpenShift     | 4.6<br/>4.7<br/>4.8                      |
| Helm          | 3.5.4 (Linux)                            |
| kubectl       | 1.16.0                                   |

The following matrix displays the tested package versions for our Helm chart.

| Sumo Logic Helm Chart | kube-prometheus-stack/Prometheus Operator | FluentD | Fluent Bit                          | Falco  | Metrics Server | Telegraf Operator | Tailing Sidecar Operator |
|:----------------------|:------------------------------------------|:--------|:------------------------------------|:-------|:---------------|:------------------|:-------------------------|
| 2.7.0 - latest        | 12.10.0                                   | 1.14.6  | 0.14.1                              | 1.17.4 | 5.8.4          | 1.3.3             | 0.3.2                    |
| 2.6.0                 | 12.10.0                                   | 1.14.4  | 0.14.1                              | 1.16.2 | 5.8.4          | 1.3.3             | 0.3.2                    |
| 2.5.0 - 2.5.2         | 12.10.0                                   | 1.14.4  | 0.12.1                              | 1.16.2 | 5.8.4          | 1.3.3             | 0.3.2                    |
| 2.4.0 - 2.4.1         | 12.10.0                                   | 1.12.2  | 0.12.1                              | 1.16.2 | 5.8.4          | 1.3.3             | 0.3.1                    |
| 2.3.0 - 2.3.2         | 12.10.0                                   | 1.12.2  | 0.12.1                              | 1.16.2 | 5.8.4          | 1.3.3             | 0.3.1                    |
| 2.2.0                 | 12.10.0                                   | 1.12.2  | 0.12.1                              | 1.7.10 | 5.8.4          | 1.2.0             | 0.3.1                    |
| 2.1.6                 | 12.3.0                                    | 1.12.2  | 0.12.1                              | 1.7.10 | 5.8.4          | 1.2.0             | 0.3.0                    |
| 2.1.1 - 2.1.5         | 12.3.0                                    | 1.12.2  | 0.12.1 (downgraded)                 | 1.7.10 | 5.8.4          | 1.1.5             | 0.3.0                    |
| 2.1.0                 | 12.3.0                                    | 1.12.1  | 0.15.1                              | 1.7.10 | 5.8.1          | 1.1.5             | 0.3.0                    |
| 2.0.2 - 2.0.5         | 12.3.0                                    | 1.12.0  | 0.11.0                              | 1.5.7  | 5.0.2          | 1.1.5             | -                        |
| 2.0.0 - 2.0.1         | 12.3.0                                    | 1.11.5  | 0.7.13 (new fluent repository)      | 1.5.7  | 5.0.2          | 1.1.5             | -                        |
| 1.3.6                 | 9.3.4                                     | 1.11.5  | 2.10.1 (old helm-stable repository) | 1.5.7  | 2.11.2         | 1.1.6             | -                        |
| 1.3.5                 | 9.3.4                                     | 1.11.1  | 2.10.1 (old helm-stable repository) | 1.5.7  | 2.11.2         | 1.1.6             | -                        |
| 1.3.1 - 1.3.4         | 9.3.4                                     | 1.11.1  | 2.10.1                              | 1.4.0  | 2.11.2         | 1.1.6             | -                        |
| 1.3.0                 | 9.3.4                                     | 1.11.1  | 2.10.1                              | 1.4.0  | 2.11.2         | 1.1.4             | -                        |
| 1.2.0 - 1.2.3         | 8.13.8                                    | 1.11.1  | 2.8.14                              | 1.1.8  | 2.11.1         | -                 |                          |
| 1.1.0                 | 8.13.8                                    | 1.8.1   | 2.8.14                              | 1.1.8  | 2.11.1         | -                 |                          |
| 1.0.0                 | 8.2.0                                     | 1.8.1   | 2.8.1                               | 1.1.6  | 2.7.0          | -                 |                          |
| 0.17.0 - 0.17.4       | 8.2.0                                     | 1.6.3   | 2.8.1                               | 1.1.0  | 2.7.0          | -                 |                          |
| 0.14.0 - 0.16.0       | 8.2.0                                     | 1.6.3   | 2.8.1                               | 1.1.1  | 2.7.0          | -                 |                          |
| 0.13.0                | 8.2.0                                     | 1.6.3   | 2.8.1                               | 1.0.11 | 2.7.0          | -                 |                          |
| 0.12.0                | 8.2.0                                     | 1.6.3   | 2.8.1                               | 1.0.9  | -              | -                 |                          |
| 0.9.0 - 0.11.0        | 6.2.1                                     | 1.6.3   | 2.4.4                               | 1.0.8  | -              | -                 |                          |
| 0.6.0 - 0.8.0         | 6.2.1                                     | 1.6.3   | 2.4.4                               | 1.0.5  | -              | -                 |                          |

### ARM support

The collection Helm Chart supports AWS Graviton CPUs, and has been tested in ARM-based EKS clusters. In principle, it
should run fine on any ARM64 node, but there is currently no official support for non-AWS ARM environments. If you do
however run into problems in such an environment, don't hesitate to open an [issue][issues] describing them.

The only exception to the above is Falco, which currently lacks official ARM Docker images. See
[this issue][falco] for more information.

[falco]: https://github.com/falcosecurity/falco/issues/1589
[issues]: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues
