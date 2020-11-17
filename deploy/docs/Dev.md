# Development

This document contains information helpful for developers.

## Installation of non-official Helm charts

Non-official Helm charts are available in [dev](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/gh-pages/dev) directory on [gh-pages](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/gh-pages) branch.

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
        --version 2.0.0-dev.0-81-g07e8e27f \
        -f /sumologic/vagrant/values.yaml,/sumologic/vagrant/values.local.yaml
```
