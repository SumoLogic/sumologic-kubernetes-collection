# Deployment Guide for unreleased version

This page has instructions for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level
metadata; and sending them to Sumo Logic. See our [documentation guide](https://help.sumologic.com/docs/observability/kubernetes/) for
details on our Kubernetes Solution.

- [Solution overview](#solution-overview)
- [Minimum Requirements](#minimum-requirements)
- [Support Matrix](#support-matrix)
  - [ARM support](#arm-support)
  - [Falco support](#falco-support)

Documentation for other versions can be found in the
[main README file](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/README.md#documentation).

---

Documentation links:

- [Installation](/docs/installation.md)

- Configuration

  - [Examples](/docs/configuration-examples.md)
  - Logs
    - [Collecting container logs](/docs/collecting-container-logs.md)
  - [Advanced Configuration/Best Practices](/docs/best-practices.md)
  - [Advanced Configuration/Security best practices](/docs/security-best-practices.md)
  - [Authenticating with container registry](/docs/working-with-container-registries.md#authenticating-with-container-registry)
    - [Using pull secrets with `sumologic-kubernetes-collection` helm chart](/docs/working-with-container-registries.md#authenticating-with-container-registry)
  - [Collecting Kubernetes events](/docs/collecting-kubernetes-events.md)
  - Open Telemetry
    - [Open Telemetry with `sumologic-kubernetes-collection`](/docs/opentelemetry-collector.md)
    - [Comparison of Fluentd and Opentelemetry Collector functionality](/docs/fluent/fluentd-otc-comparison.md)
    - [Traces - auto-instrumentation in Kubernetes](https://help.sumologic.com/docs/apm/traces/get-started-transaction-tracing/opentelemetry-instrumentation/kubernetes)
  - Fluentd and Fluent-Bit
    - [Adding Additional Fluentd Plugins](/docs/fluent/additional-fluentd-plugins.md)
    - [Container log parsing with Fluent-Bit (Docker, CRI-O, containerd)](/docs/fluent/container-logs.md)
    - [Performance estimates for running collection chart](/docs/fluent/performance.md)
    - [Fluentd persistence](/docs/fluent/fluentd-persistence.md)

- Upgrades

  - [Upgrade from v2 to v3][migration-doc-v3]
  - [Upgrade from v2.17 to v2.18][migration-doc-v2.18]
  - [Upgrade from v1.3 to v2.0][migration-doc-v2]
  - [Upgrade from v0.17 to v1.0][migration-doc-v1]
  - [Migrate from `SumoLogic/fluentd-kubernetes-sumologic`][migration-steps]

- [Troubleshooting Collection](/docs/troubleshoot-collection.md)
- [Monitoring the Monitoring](/docs/monitoring-lag.md)
- [Dev Releases](/docs/dev.md)

[migration-doc-v3]: ./v3-migration-doc.md
[migration-doc-v2.18]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v2-18-migration.md
[migration-doc-v2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v2_migration_doc.md
[migration-doc-v1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v1_migration_doc.md
[migration-steps]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/Migration_Steps.md

## Solution overview

The diagrams below illustrate the components of the Kubernetes collection solution.

### Log Collection

![logs](/images/logs.png)

### Metrics Collection

![metrics](/images/metrics.png)

### Kubernetes Events Collection

![events](/images/events.png)

## Minimum Requirements

| Name | Version |
| ---- | ------- |
| K8s  | 1.21+   |
| Helm | 3.5+    |

## Support Matrix

The following table displays the tested Kubernetes and Helm versions.

| Name                   | Version                                  |
| ---------------------- | ---------------------------------------- |
| K8s with EKS           | 1.22<br/>1.23<br/>1.24<br/>1.25<br/>1.26 |
| K8s with EKS (fargate) | 1.24<br/>1.25<br/>1.26                   |
| K8s with Kops          | 1.22<br/>1.23<br/>1.24<br/>1.25<br/>1.26 |
| K8s with GKE           | 1.23<br/>1.24<br/>1.25<br/>1.26          |
| K8s with AKS           | 1.24<br/>1.25<br/>1.26                   |
| OpenShift              | 4.10<br/>4.11<br/>4.12                   |
| Helm                   | 3.8.2 (Linux)                            |
| kubectl                | 1.23.6                                   |

The following table displays the currently used software versions for our Helm chart.

| Name                                      | Version |
| ----------------------------------------- | ------- |
| OpenTelemetry Collector                   | 0.76.1  |
| OpenTelemetry Operator                    | 0.24.0  |
| kube-prometheus-stack/Prometheus Operator | 40.5.0  |
| Falco                                     | 2.4.2   |
| Telegraf Operator                         | 1.3.10  |
| Tailing Sidecar Operator                  | 0.5.5   |
| Fluentd                                   | 1.15.3  |
| Fluent Bit                                | 1.6.10  |

### ARM support

The collection Helm Chart supports AWS Graviton CPUs, and has been tested in ARM-based EKS clusters. In principle, it should run fine on any
ARM64 node, but there is currently no official support for non-AWS ARM environments. If you do however run into problems in such an
environment, don't hesitate to open an [issue][issues] describing them.

[issues]: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues

### Falco support

Falco is embedded in this Helm Chart for user convenience only - Sumo Logic does not provide production support for it.
