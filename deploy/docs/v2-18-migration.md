# Upgrading from v2.17 to v2.18

## Upgrade OpenTelemetry Operator CRDs

### Do I need to do this?

You need to do this if you have the OpenTelemetry Operator subchart enabled with `opentelemetry-operator.enabled: true` in your values file.

### What do I need to do?

Run the following commands on the cluster before upgrading the chart:

```shell
kubectl apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/open-telemetry/opentelemetry-helm-charts/opentelemetry-operator-0.24.0/charts/opentelemetry-operator/crds/crd-opentelemetrycollector.yaml
kubectl apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/open-telemetry/opentelemetry-helm-charts/opentelemetry-operator-0.24.0/charts/opentelemetry-operator/crds/crd-opentelemetryinstrumentation.yaml
```

### Why do I need to do this?

The OpenTelemetry Operator subchart was upgraded from [v0.13.0][ot-operator-v0.13.0] to [v0.18.3][ot-operator-v0.18.3]. The new chart introduces a new feature in the Instrumentation CRD.
If you do not upgrade the CRDs, the `release-name-ot-operator-instr` job will fail.

[ot-operator-v0.13.0]: https://github.com/open-telemetry/opentelemetry-helm-charts/releases/opentelemetry-operator-0.13.0
[ot-operator-v0.18.3]: https://github.com/open-telemetry/opentelemetry-helm-charts/releases/opentelemetry-operator-0.18.3
