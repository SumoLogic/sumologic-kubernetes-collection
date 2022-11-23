# Development

This document contains information helpful for developers.

## Installation of non-official Helm charts

| DISCLAIMER                                                                                                                                                                 |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| We recommend testing dev releases on non-production clusters. <br/> These releases are generated continuously from contributions to this repo and may not be fully tested. |

Non-official Helm charts are available in [dev] directory on [gh-pages] branch.

[dev]: https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/gh-pages/dev
[gh-pages]: https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/gh-pages

To use non-official Helm charts it is necessary to add repository containing them:

```bash
helm repo add sumologic-dev https://sumologic.github.io/sumologic-kubernetes-collection/dev
helm repo update
```

To install/upgrade Helm chart you can use `helm upgrade` command with following arguments:

```bash
helm upgrade <release> sumologic-dev/sumologic \
        --install \
        --namespace <namespace> \
        --version <version> \
        -f <values>
```

e.g.

```bash
helm upgrade collection sumologic-dev/sumologic \
        --install \
        --namespace sumologic \
        --version 2.0.0-dev.0-83-g7cbe1a27 \
        -f /sumologic/vagrant/values.yaml,/sumologic/vagrant/values.local.yaml
```
