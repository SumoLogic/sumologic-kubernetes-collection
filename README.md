# sumologic-kubernetes-collection

This repo contains all the necessary resources to collect observability data from Kubernetes clusters and send it to Sumo Logic. Sumo Logic
leverages [CNCF](https://www.cncf.io) supported technology including [OpenTelemetry](https://opentelemetry.io),
[Prometheus](https://prometheus.io) and [Falco](https://www.falco.org/) to collect logs, metrics and traces from Kubernetes clusters. The
following diagram provides an overview of the collection process.

![overview](/images/overview-v3.png)

## Installation

Detailed instructions are available in our Installation Guides in documentation below.

## Documentation

Sumo Logic Helm Chart Version

| version                                                                                                   | status                                  |
| --------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| [v3.8](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.8/docs/README.md)     | current / supported                     |
| [v3.7](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.7/docs/README.md)     | deprecated / supported until 2023-11-22 |
| [v3.6](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.6/docs/README.md)     | deprecated / supported until 2023-11-11 |
| [v3.5](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.5/docs/README.md)     | deprecated / supported until 2023-11-04 |
| [v3.4](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.4/docs/README.md)     | deprecated / supported until 2023-10-14 |
| [v3.3](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.3/docs/README.md)     | deprecated / supported until 2023-09-27 |
| [v3.2](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.2/docs/README.md)     | deprecated / supported until 2023-09-01 |
| [v3.1](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.1/docs/README.md)     | deprecated / supported until 2023-08-09 |
| [v3.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.0/docs/README.md)     | deprecated / supported until 2023-07-20 |
| [v2.19](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.19/deploy/README.md) | deprecated / supported until 2023-05-24 |
| [v2.18](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.18/deploy/README.md) | deprecated / unsupported                |
| [v2.17](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.17/deploy/README.md) | deprecated / unsupported                |
| [v2.16](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.16/deploy/README.md) | deprecated / unsupported                |
| [v2.15](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.15/deploy/README.md) | deprecated / unsupported                |
| [v2.14](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.14/deploy/README.md) | deprecated / unsupported                |
| [v2.13](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.13/deploy/README.md) | deprecated / unsupported                |
| [v2.12](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.12/deploy/README.md) | deprecated / unsupported                |
| [v2.11](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.11/deploy/README.md) | deprecated / unsupported                |
| [v2.10](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.10/deploy/README.md) | deprecated / unsupported                |
| [v2.9](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.9/deploy/README.md)   | deprecated / unsupported                |
| [v2.8](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.8/deploy/README.md)   | deprecated / unsupported                |
| [v2.7](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.7/deploy/README.md)   | deprecated / unsupported                |
| [v2.6](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.6/deploy/README.md)   | deprecated / unsupported                |
| [v2.5](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.5/deploy/README.md)   | deprecated / unsupported                |
| [v2.4](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.4/deploy/README.md)   | deprecated / unsupported                |
| [v2.3](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.3/deploy/README.md)   | deprecated / unsupported                |
| [v2.2](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.2/deploy/README.md)   | deprecated / unsupported                |
| [v2.1](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.1/deploy/README.md)   | deprecated / unsupported                |
| [v2.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.0/deploy/README.md)   | deprecated / unsupported                |
| [v1.3](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v1.3/deploy/README.md)   | deprecated / unsupported                |
| [v0.17](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v0.17/deploy/README.md) | deprecated / unsupported                |

## Roadmap

Please refer to [roadmap](ROADMAP.md) document.

## License

This project is released under the [Apache 2.0 License](./LICENSE).

## Contributing

Please refer to our [Contributing](./CONTRIBUTING.md) documentation to get started.

## Code Of Conduct

Please refer to our [Code of Conduct](CODE_OF_CONDUCT.md).
