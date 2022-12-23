# Deployment Guide for unreleased version

This page has instructions for collecting Kubernetes logs, metrics, and events;
enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic.
See our [documentation guide](https://help.sumologic.com/docs/observability/kubernetes/)
for details on our Kubernetes Solution.

- [Solution overview](#solution-overview)
- [Minimum Requirements](#minimum-requirements)
- [Support Matrix](#support-matrix)
  - [ARM support](#arm-support)
  - [Falco support](#falco-support)

Documentation for other versions can be found in the [main README file](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/README.md#documentation).

---

Documentation links:

- Installation
  - [Installation with Helm](/docs/installation-with-helm.md)
  - [Non Helm Installation](/docs/non-helm-installation.md)

- Configuration
  - [Additional Prometheus configuration](/docs/additional-prometheus-configuration.md)
  - [Advanced Configuration/Best Practices](/docs/best-practices.md)
  - [Advanced Configuration/Security best practices](/docs/security-best-practices.md)
  - [Authenticating with container registry](/docs/working-with-container-registries.md#authenticating-with-container-registry)
    - [Using pull secrets with `sumologic-kubernetes-collection` helm chart](/docs/working-with-container-registries.md#authenticating-with-container-registry)
  - [Collecting Kubernetes events](/docs/collecting-kubernetes-events.md)
  - Open Telemetry `beta`
    - [Open Telemetry with `sumologic-kubernetes-collection`](/docs/opentelemetry-collector.md)
    - [Comparison of Fluentd and Opentelemetry Collector functionality](/docs/fluent/fluentd-otc-comparison.md)
    - [Traces - auto-instrumentation in Kubernetes](https://help.sumologic.com/docs/apm/traces/get-started-transaction-tracing/opentelemetry-instrumentation/kubernetes)
  - FluentD and Fluent-Bit
    - [Adding Additional FluentD Plugins](/docs/fluent/additional-fluentd-plugins.md)
    - [Container log parsing with Fluent-Bit (Docker, CRI-O, containerd)](/docs/fluent/container-logs.md)
    - [Performance estimates for running collection chart](/docs/fluent/performance.md)
    - [FluentD persistence](/docs/fluent/fluentd-persistence.md)
- Upgrades
  - [Upgrade from v0.17 to v1.0][migration-doc-v1]
  - [Upgrade from v1.3 to v2.0][migration-doc-v2]

- [Migration steps from `SumoLogic/fluentd-kubernetes-sumologic`][migration-steps]
- [Troubleshooting Collection](/docs/troubleshoot-collection.md)
- [Monitoring the Monitoring](/docs/monitoring-lag.md)
- [Dev Releases](/docs/dev.md)

[migration-doc-v1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v1_migration_doc.md
[migration-doc-v2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v2_migration_doc.md
[migration-steps]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/Migration_Steps.md

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
| Helm | 3.5+    |

## Support Matrix

The following table displays the tested Kubernetes and Helm versions.

| Name          | Version                         |
|---------------|---------------------------------|
| K8s with EKS  | 1.20<br/>1.21<br/>1.22<br/>1.23 |
| K8s with Kops | 1.21<br/>1.22<br/>1.23<br/>1.24 |
| K8s with GKE  | 1.21<br/>1.22<br/>1.23          |
| K8s with AKS  | 1.22<br/>1.23<br/>1.24          |
| OpenShift     | 4.8<br/>4.9<br/>4.10            |
| Helm          | 3.8.2 (Linux)                   |
| kubectl       | 1.23.6                          |

The following matrix displays the tested package versions for our Helm chart.

| Sumo Logic Helm Chart | kube-prometheus-stack/Prometheus Operator | FluentD | Fluent Bit                          | Falco  | Metrics Server | Telegraf Operator | Tailing Sidecar Operator | OpenTelemetry Operator |
|:----------------------|:------------------------------------------|:--------|:------------------------------------|:-------|:---------------|:------------------|:-------------------------|:-----------------------|
| 3.0.0-beta.0          | 40.5.0                                    | 1.14.6  | 0.21.3                              | 2.4.2  | 6.2.4          | 1.3.10            | 0.5.5                    | 0.18.3                 |
| 2.16.0                | 12.10.0                                   | 1.14.6  | 0.20.2                              | 1.18.6 | 5.11.9         | 1.3.5             | 0.3.4                    | 0.7.0                  |
| 2.14.1 - 2.15.0       | 12.10.0                                   | 1.14.6  | 0.20.2                              | 1.18.6 | 5.11.9         | 1.3.5             | 0.3.3                    | 0.7.0                  |
| 2.11.0 - 2.14.0       | 12.10.0                                   | 1.14.6  | 0.20.2                              | 1.18.6 | 5.11.9         | 1.3.5             | 0.3.2                    | 0.7.0                  |
| 2.10.0                | 12.10.0                                   | 1.14.6  | 0.14.1                              | 1.17.4 | 5.11.9         | 1.3.3             | 0.3.2                    | 0.7.0                  |
| 2.9.0 - 2.9.1         | 12.10.0                                   | 1.14.6  | 0.14.1                              | 1.17.4 | 5.11.9         | 1.3.3             | 0.3.2                    | -                      |
| 2.8.0 - 2.8.2         | 12.10.0                                   | 1.14.6  | 0.14.1                              | 1.17.4 | 5.11.9         | 1.3.3             | 0.3.2                    | -                      |
| 2.7.0 - 2.7.3         | 12.10.0                                   | 1.14.6  | 0.14.1                              | 1.17.4 | 5.11.9         | 1.3.3             | 0.3.2                    | -                      |
| 2.6.0                 | 12.10.0                                   | 1.14.4  | 0.14.1                              | 1.16.2 | 5.11.9         | 1.3.3             | 0.3.2                    | -                      |
| 2.5.0 - 2.5.4         | 12.10.0                                   | 1.14.4  | 0.12.1                              | 1.16.2 | 5.11.9         | 1.3.3             | 0.3.2                    | -                      |
| 2.4.0 - 2.4.3         | 12.10.0                                   | 1.12.2  | 0.12.1                              | 1.16.2 | 5.11.9         | 1.3.3             | 0.3.1                    | -                      |
| 2.3.0 - 2.3.2         | 12.10.0                                   | 1.12.2  | 0.12.1                              | 1.16.2 | 5.11.9         | 1.3.3             | 0.3.1                    | -                      |
| 2.2.0 - 2.2.2         | 12.10.0                                   | 1.12.2  | 0.12.1                              | 1.7.10 | 5.11.9         | 1.2.0             | 0.3.1                    | -                      |
| 2.1.6                 | 12.3.0                                    | 1.12.2  | 0.12.1                              | 1.7.10 | 5.8.4          | 1.2.0             | 0.3.0                    | -                      |
| 2.1.1 - 2.1.5         | 12.3.0                                    | 1.12.2  | 0.12.1 (downgraded)                 | 1.7.10 | 5.8.4          | 1.1.5             | 0.3.0                    | -                      |
| 2.1.0                 | 12.3.0                                    | 1.12.1  | 0.15.1                              | 1.7.10 | 5.8.1          | 1.1.5             | 0.3.0                    | -                      |
| 2.0.2 - 2.0.5         | 12.3.0                                    | 1.12.0  | 0.11.0                              | 1.5.7  | 5.0.2          | 1.1.5             | -                        |                        |
| 2.0.0 - 2.0.1         | 12.3.0                                    | 1.11.5  | 0.7.13 (new fluent repository)      | 1.5.7  | 5.0.2          | 1.1.5             | -                        |                        |
| 1.3.6                 | 9.3.4                                     | 1.11.5  | 2.10.1 (old helm-stable repository) | 1.5.7  | 2.11.2         | 1.1.6             | -                        |                        |
| 1.3.5                 | 9.3.4                                     | 1.11.1  | 2.10.1 (old helm-stable repository) | 1.5.7  | 2.11.2         | 1.1.6             | -                        |                        |
| 1.3.1 - 1.3.4         | 9.3.4                                     | 1.11.1  | 2.10.1                              | 1.4.0  | 2.11.2         | 1.1.6             | -                        |                        |
| 1.3.0                 | 9.3.4                                     | 1.11.1  | 2.10.1                              | 1.4.0  | 2.11.2         | 1.1.4             | -                        |                        |
| 1.2.0 - 1.2.3         | 8.13.8                                    | 1.11.1  | 2.8.14                              | 1.1.8  | 2.11.1         | -                 |                          |                        |
| 1.1.0                 | 8.13.8                                    | 1.8.1   | 2.8.14                              | 1.1.8  | 2.11.1         | -                 |                          |                        |
| 1.0.0                 | 8.2.0                                     | 1.8.1   | 2.8.1                               | 1.1.6  | 2.7.0          | -                 |                          |                        |
| 0.17.0 - 0.17.4       | 8.2.0                                     | 1.6.3   | 2.8.1                               | 1.1.0  | 2.7.0          | -                 |                          |                        |
| 0.14.0 - 0.16.0       | 8.2.0                                     | 1.6.3   | 2.8.1                               | 1.1.1  | 2.7.0          | -                 |                          |                        |
| 0.13.0                | 8.2.0                                     | 1.6.3   | 2.8.1                               | 1.0.11 | 2.7.0          | -                 |                          |                        |
| 0.12.0                | 8.2.0                                     | 1.6.3   | 2.8.1                               | 1.0.9  | -              | -                 |                          |                        |
| 0.9.0 - 0.11.0        | 6.2.1                                     | 1.6.3   | 2.4.4                               | 1.0.8  | -              | -                 |                          |                        |
| 0.6.0 - 0.8.0         | 6.2.1                                     | 1.6.3   | 2.4.4                               | 1.0.5  | -              | -                 |                          |                        |

### ARM support

The collection Helm Chart supports AWS Graviton CPUs, and has been tested in ARM-based EKS clusters. In principle, it
should run fine on any ARM64 node, but there is currently no official support for non-AWS ARM environments. If you do
however run into problems in such an environment, don't hesitate to open an [issue][issues] describing them.

The only exception to the above is Falco, which currently lacks official ARM Docker images. See
[this issue][falco] for more information.

[falco]: https://github.com/falcosecurity/falco/issues/1589
[issues]: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues

### Falco support

Falco is embedded in this Helm Chart for user convenience only - Sumo Logic does not provide production support for it.
