# Collecting Kubernetes events

You can collect Kubernetes events from the Kubernetes API server and send them to Sumo Logic as logs.

This feature is enabled by default.
To disable it, set the `sumologic.events.enabled` property to `false`.

Event collection is performed by the provider specified in `sumologic.events.provider`. This can be either `fluentd` for Fluentd (which is currently the default) or `otelcol` for OpenTelemetry Collector (which will be the default in a future release).
You can switch the provider by setting the property:

```yaml
sumologic:
  events:
    provider: otelcol
```

Both providers work in the same way: they request all Kubernetes events from the Kubernetes API server.
Note that the resource API used is [core v1][event_v1_core] and not [events.k8s.io/v1][event_events_k8s_io].
The events are sent as logs in their original JSON format to Sumo Logic.

Example Kubernetes event:

```json
{
  "object": {
    "apiVersion": "v1",
    "count": 19736,
    "eventTime": null,
    "firstTimestamp": "2022-03-12T20:48:26Z",
    "involvedObject": {
      "apiVersion": "v1",
      "fieldPath": "spec.containers{aws-node}",
      "kind": "Pod",
      "name": "aws-node-sshmk",
      "namespace": "kube-system",
      "resourceVersion": "55028103",
      "uid": "96a623cd-e201-4ba5-9595-231cdf3da63d"
    },
    "kind": "Event",
    "lastTimestamp": "2022-07-05T01:47:09Z",
    "message": "Pulling image \"602401143452.dkr.ecr.us-west-1.amazonaws.com/amazon-k8s-cni:v1.7.5-eksbuild.1\"",
    "metadata": {
      "creationTimestamp": "2022-07-05T01:47:09Z",
      "name": "aws-node-sshmk.16dbbd30f2200271",
      "namespace": "kube-system",
      "resourceVersion": "86640936",
      "selfLink": "/api/v1/namespaces/kube-system/events/aws-node-sshmk.16dbbd30f2200271",
      "uid": "d7a69a2e-3842-4f26-abec-f9949158f189"
    },
    "reason": "Pulling",
    "reportingComponent": "",
    "reportingInstance": "",
    "source": {
      "component": "kubelet",
      "host": "ip-172-16-8-171.us-west-1.compute.internal"
    },
    "type": "Normal"
  },
  "timestamp": 1656985629543,
  "type": "ADDED"
}
```

## Configuration

To configure event collection, see the following sections of the [values.yaml][values_yaml] file, depending on the provider used:

- `fluentd.events` for Fluentd provider (the default)
- `otelevents` for OpenTelemetry Collector provider

Also see [OpenTelemetry Collector document][otelcol_config] for more details on configuring the Otelcol provider.

## Disabling Kubernetes events collection

To disable the collection of Kuebrnetes events, set the `sumologic.events.enabled` property to `false`:

```yaml
sumologic:
  events:
    enabled: false
```

[event_v1_core]: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#event-v1-core
[event_events_k8s_io]: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#event-v1-events-k8s-io
[values_yaml]: ../helm/sumologic/values.yaml
[otelcol_config]: ./opentelemetry_collector.md#kubernetes-events
