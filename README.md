# sumologic-kubernetes-collection

This repo contains all the necessary resources to collect observability data from Kubernetes clusters and send it to Sumo Logic. Sumo Logic
leverages [CNCF](https://www.cncf.io) supported technology including [OpenTelemetry](https://opentelemetry.io),
[Prometheus](https://prometheus.io) and [Falco](https://www.falco.org/) to collect logs, metrics and traces from Kubernetes clusters. The
following diagram provides an overview of the collection process.

![overview](/images/overview-v4.png)

## Installation

Detailed instructions are available in our [Installation Guides](https://help.sumologic.com/docs/send-data/kubernetes/install-helm-chart/).

## Documentation

Sumo Logic Helm Chart Version

### Supported versions

Below is a table with documentation for every supported minor release. EOL for the latest release will be six months after next minor
release.

| version                                                                                                 | planned end of life date |
| ------------------------------------------------------------------------------------------------------- | ------------------------ |
| [v4.5](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v4.5/docs/README.md)   | TBA                      |
| [v4.4](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v4.4/docs/README.md)   | 2024-08-22               |
| [v4.3](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v4.3/docs/README.md)   | 2024-07-24               |
| [v4.2](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v4.2/docs/README.md)   | 2024-06-13               |
| [v4.1](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v4.1/docs/README.md)   | 2024-05-27               |
| [v4.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v4.0/docs/README.md)   | 2024-05-03               |
| [v3.18](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.18/docs/README.md) | 2024-04-20               |
| [v3.17](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.17/docs/README.md) | 2024-04-20               |
| [v3.16](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.16/docs/README.md) | 2024-04-20               |
| [v3.15](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.15/docs/README.md) | 2024-04-18               |
| [v3.14](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.14/docs/README.md) | 2024-03-18               |
| [v3.13](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.13/docs/README.md) | 2024-03-01               |
| [v3.12](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.12/docs/README.md) | 2024-02-21               |

### Unsupported versions

| version                                                                                                   | end of life date |
| --------------------------------------------------------------------------------------------------------- | ---------------- |
| [v3.11](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.11/docs/README.md)   | 2024-02-07       |
| [v3.10](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.10/docs/README.md)   | 2024-01-28       |
| [v3.9](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.9/docs/README.md)     | 2024-01-06       |
| [v3.8](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.8/docs/README.md)     | 2023-12-14       |
| [v3.7](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.7/docs/README.md)     | 2023-11-22       |
| [v3.6](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.6/docs/README.md)     | 2023-11-11       |
| [v3.5](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.5/docs/README.md)     | 2023-11-04       |
| [v3.4](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.4/docs/README.md)     | 2023-10-14       |
| [v3.3](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.3/docs/README.md)     | 2023-09-27       |
| [v3.2](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.2/docs/README.md)     | 2023-09-01       |
| [v3.1](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.1/docs/README.md)     | 2023-08-16       |
| [v3.0](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v3.0/docs/README.md)     | 2023-08-09       |
| [v2.19](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.19/deploy/README.md) | 2023-07-20       |
| [v1.3](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v1.3/deploy/README.md)   | 2021-07-14       |
| [v0.17](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v0.17/deploy/README.md) | 2020-11-21       |

## Roadmap

Please refer to [roadmap](ROADMAP.md) document.

## License

This project is released under the [Apache 2.0 License](./LICENSE).

## Contributing

Please refer to our [Contributing](./CONTRIBUTING.md) documentation to get started.

## Code Of Conduct

Please refer to our [Code of Conduct](CODE_OF_CONDUCT.md).
