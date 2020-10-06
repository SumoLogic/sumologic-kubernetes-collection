[![Build Status](https://travis-ci.org/SumoLogic/sumologic-kubernetes-collection.svg?branch=master)](https://travis-ci.org/SumoLogic/sumologic-kubernetes-collection) [![Docker Pulls](https://img.shields.io/docker/pulls/sumologic/kubernetes-fluentd.svg)](https://hub.docker.com/r/sumologic/kubernetes-fluentd) 

# sumologic-kubernetes-collection

This repo contains all required resources to collect data from Kubernetes clusters into Sumo Logic. Sumo Logic leverages [CNCF](https://www.cncf.io) supported technology including [Fluent-Bit](https://fluentbit.io), [FluentD](https://www.fluentd.org) and [Prometheus](https://prometheus.io) to collect logs from Kubernetes clusters. The following diagram provides an overview of the collection process.

![overview](/images/overview.png)

# Installation

Detailed instructions are available in our Installation Guides below.

Sumo Logic Helm Chart Version
| version | status |
|--|--|
|[v1.3](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v1.3/deploy/README.md) | current / supported  |
|[v1.2](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v1.2/deploy/README.md) | deprecated  |
|[v1.1](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v1.1/deploy/README.md) | deprecated  |
|[v1.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v1.0/deploy/README.md) | deprecated  |
|[v0.17](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v0.17/deploy/README.md) | deprecated  |

# License

This project is released under the [Apache 2.0 License](./LICENSE).

# Contributing

Please refer to our [Contributing](./CONTRIBUTING.md) documentation to get started.

# Code Of Conduct

Please refer to our [Code of Conduct](CODE_OF_CONDUCT.md).
