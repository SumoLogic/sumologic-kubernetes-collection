# Kubernetes Collection `v4.0.0` - Breaking Changes

<!-- TOC -->

- [Kubernetes Collection v4.0.0 - Breaking Changes](#kubernetes-collection-v400---breaking-changes)
    - [Important changes](#important-changes)
        - [OpenTelemetry Collector](#opentelemetry-collector)
    - [How to upgrade](#how-to-upgrade)
        - [Requirements](#requirements)
        - [Metrics migration](#metrics-migration)
        - [Removing support for Fluent Bit and Fluentd](#removing-support-for-fluent-bit-and-fluentd)
            - [Migration of custom configuration](#migration-of-custom-configuration)
        - [Switch to OTLP sources](#switch-to-otlp-sources)
        - [Running the helm upgrade](#running-the-helm-upgrade)
        - [Known issues](#known-issues)
    - [Full list of changes](#full-list-of-changes)

<!-- /TOC -->

Based on feedback from our users, we will be introducing several changes to the Sumo Logic Kubernetes Collection solution.

This document describes the major changes and the necessary migration steps.

## Important changes

### OpenTelemetry Collector

The new version replaces both Fluentd and Fluent Bit with the OpenTelemetry Collector. In the majority of cases, this doesn't require any
manual intervention. However, custom processing in Fluentd or Fluent Bit will need to be ported to the OpenTelemetry Collector configuration
format. Please check [Solution Overview][solution-overview] and see below for details.

[solution-overview]: /docs/README.md#solution-overview

## How to upgrade

### Requirements

- `helm3`
- `kubectl`

Set the following environment variables that our commands will make use of:

```bash
export NAMESPACE=...
export HELM_RELEASE_NAME=...
```

### Metrics migration

:construction:

### Removing support for Fluent Bit and Fluentd

Te following changes are required in order to switch to OpenTelemetry:

- `fluent-bit.*` has to be removed from `user-values.yaml`
- `sumologic.logs.collector.allowSideBySide` should be removed from `user-values.yaml`
- `sumologic.logs.defaultFluentd.*` should be removed from `user-values.yaml`
- `fluentd.*` should be removed from `user-values.yaml`
- `sumologic.logs.metadata.provider` should be removed from `user-values.yaml`
- `sumologic.metrics.metadata.provider` should be removed from `user-values.yaml`

#### Configuration Migration

In order to migrate your custom configuration, please carefully read and apply to your needs the following documents:

- [Collecting Container Logs](./collecting-container-logs.md)
- [Collecting Application Metrics](./collecting-application-metrics.md)
- [Collecting Kubernetes Events](./collecting-kubernetes-events.md)
- [Collecting Kubernetes Metrics](./collecting-kubernetes-metrics.md)

### Switch to OTLP sources

:construction:

### Running the helm upgrade

Once you've taken care of any manual steps necessary for your configuration, run the helm upgrade:

```bash
helm upgrade --namespace "${NAMESPACE}" "${HELM_RELEASE_NAME}" sumologic/sumologic --version=4.0.0 -f new-values.yaml
```

After you're done, please review the [full list of changes](#full-list-of-changes), as some of them may impact you even if they don't
require additional action.

### Known issues

:construction:

## Full list of changes

:construction:
