# Contributing Guide

To contribute you will need to ensure you have the following setup:

- You have a working [Docker environment](https://docs.docker.com/engine).
- You have a working [Ruby environment](https://ruby-doc.org).

Then clone the repo and run ci/build.sh for building and running unit test.

```text
git clone https://github.com/SumoLogic/sumologic-kubernetes-collection.git
./ci/build.sh
```

There is a prepared Vagrant environment with [microk8s](https://microk8s.io/) set up for collection tests, for details see
[here](vagrant/README.md).

## Releasing guide

In order to relase, please follow [the releasing guide][release].

[release]: ./deploy/docs/release.md
