# Contributing Guide

## Setting up a development environment

### Using Vagrant

1. Install `vagrant` as per <https://developer.hashicorp.com/vagrant/downloads>
1. Configure a provider
1. Run `vagrant up` and then `vagrant ssh`

There is a prepared Vagrant environment with [microk8s](https://microk8s.io/) set up for collection tests, for details see
[here](vagrant/README.md).

### Using nix

1. [Install nix](https://nixos.org/download.html)

   ```
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

1. Run `nix-shell` in the project root and wait for dependencies to be installed
1. In order to run integration tests, you'll need the Docker daemon installed separately

#### Use direnv to automatically load the shell when entering the directory

1. [Install direnv](https://direnv.net/docs/installation.html) You can use nix for this by running `nix-env -i direnv`.
1. Hook it into your [shell](https://direnv.net/docs/hook.html)
1. Run `direnv allow .` in the project root

## Releasing guide

In order to relase, please follow [the releasing guide][release].

[release]: ./deploy/docs/release.md

## Updating OpenTelemetry Collector image

Example:

```shell
make update-otc OTC_CURRENT_VERSION=0.73.0-sumo-1 OTC_NEW_VERSION=0.74.0-sumo-0
```

Note: this make target uses GNU `sed`. If you're on a Mac, see e.g. [here](https://stackoverflow.com/a/56007296/4603021).

You should examine the resulting changes as the automated tool can make mistakes. It's just a dummy "search and replace" under the hood.

What it does is:

- It updates the OTC image version (for logs, metrics and traces) in the chart's values file and README file.
- It updates the OTC image version in test files.
- It updates the links to the documentation of OTC components, e.g. [here](./deploy/helm/sumologic/conf/logs/otelcol/config.yaml).
