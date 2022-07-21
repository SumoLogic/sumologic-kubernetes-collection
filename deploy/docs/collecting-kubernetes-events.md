# Collecting Kubernetes events

You can collect Kubernetes events from the Kubernetes API server and send them to Sumo Logic as logs.

This feature is enabled by default.
To disable it, set the `sumologic.events.enabled` property to `false`.

The event collector collects events by requesting all Kubernetes events from the Kubernetes API server.
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

Event collection configuration can be found under the `sumologic.events` key of the [values.yaml][values_yaml] file.

### Setting source name and category

It's possible to customize the [source name][source_name] and [category][source_category] for events:

```yaml
sumologic:
  events:
    sourceName: myEventSource
    sourceCategory: myCustomSourceCategory
```

### Customizing persistence

By default, the event collector provisions and uses a Kubernetes PersistentVolume to persist some information over service restarts.
In particular, the collector remembers the most recently processed Event this way, thus avoiding having to reprocess past Events
after restart. The Persistent Volume is also used to buffer Event data if the remote destination is inaccessible.

Persistence can be customized via the `sumologic.events.persistence` section:

```yaml
sumologic:
  events:
    persistence:
      size: 10Gi
      path: /var/lib/storage/events
      accessMode: ReadWrite
```

#### Disabling persistence

Persistence can be disabled by setting `sumologic.events.persistence.enabled` to `false`. Keep in mind that doing so will cause
either duplication or data loss whenever the collector is restarted. By default, the collector reads Events 1 minute into the past
from its start time.

### Configuring the event provider

Event collection is performed by the provider specified in `sumologic.events.provider`. This can be either `fluentd` for Fluentd (which is currently the default) or `otelcol` for OpenTelemetry Collector (which will be the default in a future release).
You can switch the provider by setting the property:

```yaml
sumologic:
  events:
    provider: otelcol
```

To change provider-specific configuration, see the following sections of the [values.yaml][values_yaml] file, depending on the provider used:

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
[source_category]: https://help.sumologic.com/03Send-Data/Sources/04Reference-Information-for-Sources/Metadata-Naming-Conventions#Source_Categories
[source_name]: https://help.sumologic.com/03Send-Data/Sources/04Reference-Information-for-Sources/Metadata-Naming-Conventions#Source_Name
