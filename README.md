[![Build Status](https://travis-ci.org/SumoLogic/sumologic-kubernetes-collection.svg?branch=master)](https://travis-ci.org/SumoLogic/sumologic-kubernetes-collection) [![Docker Pulls](https://img.shields.io/docker/pulls/sumologic/kubernetes-fluentd.svg)](https://hub.docker.com/r/sumologic/kubernetes-fluentd) 

# sumologic-kubernetes-collection

| DISCLAIMER |
| --- |
| As this repo is in active development, we recommend using the collection pipeline detailed [here](https://github.com/SumoLogic/fluentd-kubernetes-sumologic) for production systems until further notice. |

Please refer to [our documentation](./deploy/README.md) on how to collect data from your Kubernetes clusters into Sumo Logic.

This repo contains all required resources to collect data from Kubernetes clusters into Sumo Logic. Sumo Logic leverages [CNCF](https://www.cncf.io) supported technology including [Fluent-Bit](https://fluentbit.io), [FluentD](https://www.fluentd.org) and [Prometheus](https://prometheus.io) to collect logs from Kubernetes clusters. The following diagram provides an overview of the collection process.

![overview](/images/overview.png)

# License

This project is released under the [Apache 2.0 License](./LICENSE).

# Contributing

Please refer to our [Contributing](./CONTRIBUTING.md) documentation to get started.

# Code Of Conduct

Please refer to our [Code of Conduct](CODE_OF_CONDUCT.md).