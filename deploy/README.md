# Deployment Guide

This page has instructions for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic. See our [documentation guide](https://help.sumologic.com/Solutions/Kubernetes_Solution) for details on our Kubernetes Solution.

- [Deployment Guide](#deployment-guide)
  - [Solution overview](#solution-overview)
  - [Minimum Requirements](#minimum-requirements)
  - [Support Matrix](#support-matrix)
  - [Installation with Helm](./docs/Installation_with_Helm.md)
  - [Upgrading with Helm](./docs/Upgrading_with_Helm.md) 
  - [Non Helm Installation](./docs/Non_Helm_Installation.md) 
  - [Adding Additional FluentD Plugins](./docs/Additional_Fluentd_Plugins.md)
  - [Advanced Configuration/Best Practices](./docs/Best_Practices.md)
  - [Alpha Releases](./docs/Alpha_Release_Guide.md)
- [Migration Steps](./docs/Migration_Steps.md)
- [Troubleshooting Collection](./docs/Troubleshoot_Collection.md)
- [Monitoring the Monitoring](./docs/monitoring-lag.md)

## Solution overview

The diagram below illustrates the components of the Kubernetes collection solution.

![solution](/images/k8s_collection_diagram.png)

* **K8S API Server**. Exposes API server metrics.
* **Scheduler.** Makes Scheduler metrics available on an HTTP metrics port.
* **Controller Manager.** Makes Controller Manager metrics available on an HTTP metrics port.
* **node-exporter.** The `node_exporter` add-on exposes node metrics, including CPU, memory, disk, and network utilization.
* **kube-state-metrics.** Listens to the Kubernetes API server; generates metrics about the state of the deployments, nodes, and pods in the cluster; and exports the metrics as plaintext on an HTTP endpoint listen port.
* **Prometheus deployment.** Scrapes the metrics exposed by the `node-exporter` add-on for Kubernetes and the `kube-state-metric`s component; writes metrics to a port on the Fluentd deployment.
* **Fluentd deployment.** Forwards logs and metrics to HTTP sources on a hosted collector. Includes multiple Fluentd plugins that parse and format the metrics and enrich them with metadata.
* **Events Fluentd deployment.** Forwards events to an HTTP source on a hosted collector.

## Minimum Requirements

Name | Version
-------- | -----
K8s | 1.10+
Helm | 2.12+

## Support Matrix

The following table displays the tested Kubernetes and Helm versions.

Name | Version
-------- | -----
K8s with EKS | 1.13.8
|| 1.11.10
K8s with Kops | 1.13.10-k8s<br>1.13.0-kops
|| 1.12.8-k8s<br>1.12.2-kops
||1.10.13-k8s<br>1.10.0-kops
K8s with GKE | 1.12.8-gke.10<br>1.12.7-gke.25<br>1.11.10-gke.5
K8s with AKS | 1.12.8
Helm | 2.14.13 (Linux)
kubectl | 1.15.0

NOTE: Helm 3 compatibility is in the early stages and is not fully tested or supported. Please refer to this [guide](docs/Helm3.md) for more information on Helm 3. We recommend you thoroughly test the use of Helm 3 in your pre-production environments before use.

The following matrix displays the tested package versions for our Helm chart.

Sumo Logic Helm Chart | Prometheus Operator | Fluent Bit | Falco  | Metrics Server
|:-------- |:-------- |:-------- |:-------- |:--------
0.14.0 - Latest | 8.2.0 | 2.8.1 | 1.1.1 | 2.7.0
0.13.0 | 8.2.0 | 2.8.1 | 1.0.11 | 2.7.0
0.12.0 | 8.2.0 | 2.8.1 | 1.0.9  |  -
0.9.0 - 0.11.0 | 6.2.1 | 2.4.4 | 1.0.8   |  -
0.6.0 - 0.8.0 | 6.2.1 | 2.4.4 | 1.0.5    |  -
