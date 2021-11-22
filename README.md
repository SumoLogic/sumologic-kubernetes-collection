# sumologic-kubernetes-collection

This repo contains all required resources to collect data from Kubernetes clusters into Sumo Logic. Sumo Logic leverages [CNCF](https://www.cncf.io) supported technology including [Fluent-Bit](https://fluentbit.io), [FluentD](https://www.fluentd.org) , [Falco](https://www.falco.org/) and [Prometheus](https://prometheus.io) to collect logs from Kubernetes clusters. The following diagram provides an overview of the collection process.

![overview](/images/overview.png)

## Installation

Detailed instructions are available in our Installation Guides below.

Sumo Logic Helm Chart Version

| version                                                                                                   | status                   |
|-----------------------------------------------------------------------------------------------------------|--------------------------|
| [v2.2](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.2/deploy/README.md)   | current / supported      |
| [v2.1](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.1/deploy/README.md)   | deprecated / unsupported |
| [v2.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.0/deploy/README.md)   | deprecated / unsupported |
| [v1.3](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v1.3/deploy/README.md)   | deprecated / unsupported |
| [v0.17](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v0.17/deploy/README.md) | deprecated / unsupported |

## License

This project is released under the [Apache 2.0 License](./LICENSE).

## Contributing

Please refer to our [Contributing](./CONTRIBUTING.md) documentation to get started.

## Code Of Conduct

Please refer to our [Code of Conduct](CODE_OF_CONDUCT.md).
