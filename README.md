[![Build Status](https://travis-ci.org/SumoLogic/sumologic-kubernetes-collection.svg?branch=master)](https://travis-ci.org/SumoLogic/sumologic-kubernetes-collection) [![Docker Pulls](https://img.shields.io/docker/pulls/sumologic/kubernetes-fluentd.svg)](https://hub.docker.com/r/sumologic/kubernetes-fluentd) 

# sumologic-kubernetes-collection

This repo contains all required resources to collect data from Kubernetes clusters into Sumo Logic. Sumo Logic leverages [CNCF](https://www.cncf.io) supported technology including [Fluent-Bit](https://fluentbit.io), [FluentD](https://www.fluentd.org) and [Prometheus](https://prometheus.io) to collect logs from Kubernetes clusters. The following diagram provides an overview of the collection process.

![overview](/images/overview.png)

# Installation

Detailed instructions are available in our Installation Guides below.

Sumo Logic Helm Chart Version
| version | status |  
|--|--|
|[0.17.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v0.17.0/deploy/README.md)| current / supported  |
|[0.16.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v0.16.0/deploy/README.md) | deprecated |
|[0.15.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v0.15.0/deploy/README.md) | deprecated |

# License

This project is released under the [Apache 2.0 License](./LICENSE).

# Contributing

Please refer to our [Contributing](./CONTRIBUTING.md) documentation to get started.

# Code Of Conduct

Please refer to our [Code of Conduct](CODE_OF_CONDUCT.md).
