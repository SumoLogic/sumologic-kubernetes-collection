# Advanced Configuration / Best Practices

- [Overriding chart resource names with `fullnameOverride`](#overriding-chart-resource-names-with-fullnameoverride)
- [Excluding Logs From Specific Components](#excluding-logs-from-specific-components)
- [Excluding Metrics](#excluding-metrics)
- [Excluding Dimensions](#excluding-dimensions)
- [Filtering Prometheus Metrics by Namespace](#filtering-prometheus-metrics-by-namespace)
- [Modify the Log Level for Falco](#modify-the-log-level-for-falco)
- [Overriding metadata using annotations](#overriding-metadata-using-annotations)
  - [Overriding source category with pod annotations](#overriding-source-category-with-pod-annotations)
  - [Excluding data using annotations](#excluding-data-using-annotations)
    - [Including subsets of excluded data](#including-subsets-of-excluded-data)
- [Templating Kubernetes metadata](#templating-kubernetes-metadata)
  - [Missing labels](#missing-labels)
- [Disable logs, metrics, or falco](#disable-logs-metrics-or-falco)
- [Changing scrape interval for Prometheus](#changing-scrape-interval-for-prometheus)
- [Get logs not available on stdout](#get-logs-not-available-on-stdout)
- [Adding custom fields](#adding-custom-fields)
- [Using custom Kubernetes API server address](#using-custom-kubernetes-api-server-address)
  - [Compaction](#compaction)
  - [Examples](#examples)
    - [Outage with huge metrics spike](#outage-with-huge-metrics-spike)
    - [Outage with low DPM load](#outage-with-low-dpm-load)
- [Assigning Pod to particular Node](#assigning-pod-to-particular-node)
  - [Using NodeSelectors](#using-nodeselectors)
    - [Binding pods to linux nodes](#binding-pods-to-linux-nodes)
- [Parsing log content as json](#parsing-log-content-as-json)

## Overriding chart resource names with `fullnameOverride`

Here's an example of using the `fullnameOverride` properties of this chart and its subcharts
to override the created resource names.

```yaml
fullnameOverride: sl

fluent-bit:
  fullnameOverride: fb

kube-prometheus-stack:
  fullnameOverride: kps

  kube-state-metrics:
    fullnameOverride: ksm

  prometheus-node-exporter:
    fullnameOverride: pne
```

After installing the chart, the resources in the cluster will have names similar to the following:

```console
$ kubectl -n <namespace> get pods
NAME                                                 READY   STATUS        RESTARTS   AGE
fb-95sxf                                             1/1     Running       0          91s
kps-operator-6c8999bdfb-b4pks                        1/1     Running       0          91s
ksm-5dbd694cbd-mk4bd                                 1/1     Running       0          91s
pne-r64tk                                            1/1     Running       0          91s
prometheus-kps-prometheus-0                          3/3     Running       1          79s
sl-otelcol-events-0                                  1/1     Running       0          91s
sl-otelcol-logs-0                                    1/1     Running       0          91s
sl-otelcol-logs-1                                    1/1     Running       0          90s
sl-otelcol-logs-2                                    1/1     Running       0          90s
sl-otelcol-metrics-0                                 1/1     Running       0          90s
sl-otelcol-metrics-1                                 1/1     Running       0          90s
sl-otelcol-metrics-2                                 1/1     Running       0          90s
```

⚠️ **Note:** When changing the `fullnameOverride` property for an already installed chart with the `helm upgrade` command,
you need to restart the Fluent Bit and Prometheus pods
for the changed names of the Fluentd or Otelcol pods to be picked up:

```sh
helm -n <namespace> upgrade <release_name> sumologic/sumologic --values changed-fullnameoverride.yaml
kubectl -n <namespace> rollout restart daemonset <fluent_bit_daemonset_name>
kubectl -n <namespace> rollout restart statefulset <prometheus_statefulset_name>
```

As you can see from the example, every subchart has its own `fullnameOverride` property
that needs to be set separately to change the names of the resources created by that subchart.

See the chart's [README](/deploy/helm/sumologic/README.md) for all the available `fullnameOverride` properties.

## OpenTelemetry Collector Autoscaling

:construction: *TODO*, see [the FluentD section](fluent/best-practices.md#fluentd-autoscaling)

## OpenTelemetry Collector File-Based Buffer

:construction: *TODO*, see [the FluentD section](fluent/best-practices.md#fluentd-file-based-buffer)

## Excluding Logs From Specific Components

You can exclude specific logs from specific components from being sent to Sumo Logic
by specifying the following parameters either in the `user-values.yaml` file or the `helm install` command.

```
excludeContainerRegex
excludeHostRegex
excludeNamespaceRegex
excludePodRegex
```

- This is Ruby regex, so all ruby regex rules apply.
  Unlike regex in the Sumo collector, you do not need to match the entire line.
  When doing multiple patterns, put them inside of parentheses and pipe separate them.

- For things like pods and containers you will need to use a star at the end
  because the string is dynamic. Example:

  ```yaml
  excludePodRegex: "(dashboard.*|sumologic.*)"
  ```

- For things like namespace you won’t need to use a star at the end since there is no dynamic string. Example:

  ```yaml
  excludeNamespaceRegex: “(sumologic|kube-public)”
  ```

:construction: *TODO*, explain how to filter based on log message here

## Modifying logs

:construction: *TODO*, see [the FluentD section](fluent/best-practices.md#modifying-logs-in-fluentd)

## Excluding Metrics

You can filter out metrics directly in Prometheus using [this documentation](additional-prometheus-configuration.md#filter-metrics).

:construction: *TODO*, explain how to do it in OT, see [the FluentD section](fluent/best-practices.md#excluding-metrics)

## Excluding Dimensions

:construction: *TODO*, see [the FluentD section](fluent/best-practices.md#excluding-metrics)

## Collect logs from additional files on the Node

:construction: *TODO*, see [the FluentD section](fluent/best-practices.md#add-a-local-file-to-fluent-bit-configuration)

## Filtering Prometheus Metrics by Namespace

If you want to filter metrics by namespace, it can be done in the prometheus remote write config.
Here is an example of excluding kube-state metrics for namespace1 and namespace2:

```yaml
 - action: drop
   regex: kube-state-metrics;(namespace1|namespace2)
   sourceLabels: [job, namespace]
```

The section above should be added in each of the kube-state remote write blocks.

Here is another example of excluding up metrics in the sumologic namespace
while still collecting up metrics for all other namespaces:

```yaml
     # up metrics
     - url: http://collection-sumologic.sumologic.svc.cluster.local.:9888/prometheus.metrics
       writeRelabelConfigs:
       - action: keep
         regex: up
         sourceLabels: [__name__]
       - action: drop
         regex: up;sumologic
         sourceLabels: [__name__,namespace]
```

The section above should be added in each of the kube-state remote write blocks.

## Modify the Log Level for Falco

To modify the default log level for Falco, edit the following section in the `user-values.yaml` file.
Available log levels can be found in Falco's documentation here: https://falco.org/docs/configuration/.

```yaml
falco:
  ## Set the enabled flag to false to disable falco.
  enabled: true
  falco:
    json_output: true
    log_level: debug
```

## Overriding metadata using annotations

You can use [Kubernetes annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
to override some metadata and settings per pod.

- `sumologic.com/sourceCategory` overrides the value of the `sumologic.logs.container.sourceCategory` property
- `sumologic.com/sourceCategoryPrefix` overrides the value of the `sumologic.logs.container.sourceCategoryPrefix` property
- `sumologic.com/sourceCategoryReplaceDash` overrides the value of the `sumologic.logs.container.sourceCategoryReplaceDash`
  property
- `sumologic.com/sourceName` overrides the value of the `sumologic.logs.container.sourceName` property

For example:

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    app: mywebsite
  template:
    metadata:
      name: nginx
      labels:
        app: mywebsite
      annotations:
        sumologic.com/format: "text"
        sumologic.com/sourceCategory: "mywebsite/nginx"
        sumologic.com/sourceName: "mywebsite_nginx"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

### Overriding source category with pod annotations

The following example shows how to customize the source category for data from a specific deployment.
The resulting value of `_sourceCategory` field will be `my-component`:

```yaml
apiVersion: v1
kind: Deployment
metadata:
  name: my-component-deployment
spec:
  replicas: 1
  selector:
    app: my-component
  template:
    metadata:
      annotations:
        sumologic.com/sourceCategory: "my-component"
        sumologic.com/sourceCategoryPrefix: ""
        sumologic.com/sourceCategoryReplaceDash: "-"
      labels:
        app: my-component
      name: my-component
    spec:
      containers:
      - name: my-component
        image: my-image
```

The `sumologic.com/sourceCategory` annotation defines the source category for the data.

The empty `sumologic.com/sourceCategoryPrefix` annotation removes the default prefix added to the source category.

The `sumologic.com/sourceCategoryReplaceDash` annotation with value `-` prevents the dash in the source category
from being replaced with another character.

### Excluding data using annotations

You can use the `sumologic.com/exclude` [annotation](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
to exclude data from Sumo.
This data is sent to Fluentd, but not to Sumo.

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    app: mywebsite
  template:
    metadata:
      name: nginx
      labels:
        app: mywebsite
      annotations:
        sumologic.com/exclude: "true"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

#### Including subsets of excluded data

If you excluded a whole namespace, but still need one or few pods to be still included for shipping to Sumo,
you can use the `sumologic.com/include` annotation to include it.
It takes precedence over the exclusion described above.

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    app: mywebsite
  template:
    metadata:
      name: nginx
      labels:
        app: mywebsite
      annotations:
        sumologic.com/format: "text"
        sumologic.com/sourceCategory: "mywebsite/nginx"
        sumologic.com/sourceName: "mywebsite_nginx"
        sumologic.com/include: "true"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

## Templating Kubernetes metadata

The following Kubernetes metadata is available for string templating:

| String template  | Description                                             |
|------------------|---------------------------------------------------------|
| `%{namespace}`   | Namespace name                                          |
| `%{pod}`         | Full pod name (e.g. `travel-products-4136654265-zpovl`) |
| `%{pod_name}`    | Friendly pod name (e.g. `travel-products`)              |
| `%{pod_id}`      | The pod's uid (a UUID)                                  |
| `%{container}`   | Container name                                          |
| `%{source_host}` | Host                                                    |
| `%{label:foo}`   | The value of label `foo`                                |

### Missing labels

Unlike the other templates, labels are not guaranteed to exist, so missing labels
interpolate as `"undefined"`.

For example, if you have only the label `app: travel` but you define
`SOURCE_NAME="%{label:app}@%{label:version}"`, the source name will appear as `travel@undefined`.

## Disable logs, metrics, or falco

If you want to disable the collection of logs, metrics, or falco, make the below changes
respectively in the `user-values.yaml` file and run the `helm upgrade` command.

| parameter                   | value | function                   |
|-----------------------------|-------|----------------------------|
| `sumologic.logs.enabled`    | false | disable logs collection    |
| `sumologic.metrics.enabled` | false | disable metrics collection |
| `falco.enabled`             | false | disable falco              |

## Changing scrape interval for Prometheus

Default scrapeInterval for collection is `30s`. This is the recommended value which ensures that all of Sumo Logic dashboards
are filled up with proper data.

To change it, you can use following configuration:

```yaml
kube-prometheus-stack:  # For user-values.yaml
  prometheus:
    prometheusSpec:
      scrapeInterval: '1m'
```

## Get logs not available on stdout

When logs from a pod are not available on stdout, [Tailing Sidecar Operator](https://github.com/SumoLogic/tailing-sidecar)
can help with collecting them using standard logging pipeline.
To tail logs using Tailing Sidecar Operator the file with those logs needs to be accessible through a volume
mounted to sidecar container.

Providing that the file with logs is accessible through volume, to enable tailing of logs using Tailing Sidecar Operator:

- Enable Tailing Sidecar Operator by modifying `user-values.yaml`:

  ```yaml
  tailing-sidecar-operator:
    enabled: true
  ```

- Add annotation to pod from which you want to tail logs in the following format:

  ```yaml
  metadata:
    annotations:
      tailing-sidecar: <sidecar-name-0>:<volume-name-0>:<path-to-tail-0>;<sidecar-name-1>:<volume-name-1>:<path-to-tail-1>
  ```

Example of using Tailing Sidecar Operator is described in the
[blog post](https://www.sumologic.com/blog/tailing-sidecar-operator/).

## Adding custom fields

:construction: *TODO*, see [the FluentD section](fluent/best-practices.md#adding-custom-fields)

## Using custom Kubernetes API server address

In order to change API server address, the following configurations can be used.

```yaml
metadata:
  logs:
    statefulset:
      extraEnvVars:
      - name: KUBERNETES_SERVICE_HOST
        value: my-custom-k8s.api
      - name: KUBERNETES_SERVICE_PORT
        value: '12345'
  metrics:
    statefulset:
      extraEnvVars:
      - name: KUBERNETES_SERVICE_HOST
        value: my-custom-k8s.api
      - name: KUBERNETES_SERVICE_PORT
        value: '12345'
```

## OpenTelemetry Collector queueing and batching

OpenTelemetry comes with several parameters related to queue management.

For [batch processor][batch_processor]:

- `send_batch_size` defines the number of items (logs, metrics, traces) in one batch before it's sent further down the pipeline.
- `timeout` defines time after which the batch is sent regardless of the size (can be lower than `send_batch_size`).
- `send_batch_max_size` is an upper limit of the batch size.

*We could say that `send_batch_size` is a soft limit and `send_batch_max_size` is a hard limit of the batch size.*

For [sumologic exporter][sumologic_exporter]:

- `max_request_body_size` defines maximum size of requests to sumologic before compression.
- `timeout` defines connection timeout. It is recommended to adjust this value in relation to `max_request_body_size`.

- `sending_queue.num_consumers` is the number of consumers that dequeue batches. It translates to maximum number of parallel connections to the sumologic backend.
- `sending_queue.queue_size` is capacity of the queue in terms of batches (batches can vary between `1` and `send_batch_max_size`)

**As effective value of `sending_queue.queue_size` depends on current traffic,**
**there is no way to figure out optimal PVC size in relation to `sending_queue.queue_size`.**
**Due to that, we recommend to set `sending_queue.queue_size` to high value in order to use maximum resources of PVC.**

**The above in connection with PVC monitoring can lead to constant alerts (eg. [KubePersistentVolumeFillingUp][filling_up_alert]),**
**because once filled in PVC never reduces its fill.**

[batch_processor]: https://github.com/open-telemetry/opentelemetry-collector/tree/v0.47.0/processor/batchprocessor#batch-processor
[sumologic_exporter]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.50.0-sumo-0/pkg/exporter/sumologicexporter#sumo-logic-exporter
[filling_up_alert]: https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubepersistentvolumefillingup/

### Compaction

The OpenTelemetry Collector doesn't have a compaction mechanism.
Local storage can only grow - it can reuse disk space that has already been allocated, but not free it.
This leads to a situation where the database file can grow a lot (due to a spike in data traffic)
but after some time only small piece of the file will be used for data storage (until next spike).

### Examples

Here are some useful examples and calculations for queue and batch parameters.

For the calculations below we made an assumption that a single metric data point is around 1 kilobyte in size, including metadata.
This assumption is based on the average data we ingest.
Persistent storage doesn't compress data so we assume that single metric data point takes 1 kilobyte on disk as well.

`number_of_instances` represents number of `sumologic-otelcol-metrics` instances.

#### Outage with huge metrics spike

Let's consider a huge metrics spike in your network while connection to the Sumologic is down.
Huge load means that batch processor is going to push batches due to `send_batch_max_size` instead of `timeout`.
The reliability of the system can be calculated using the following formulas:

- If limited by queue_size: `number_of_instances*send_batch_max_size*sending_queue.queue_size/load_in_DPM` minutes.
- If limited by PVC size: `number_of_instances*PVC_size/(1KB*load_in_DPM)` minutes.

#### Outage with low DPM load

Let's consider a low but constant load in your network while connection to the Sumologic is down.
Low load means that batch processor is going to push batches due to `timeout` instead of `send_batch_max_size`.
The reliability of the system can be calculated using the following formulas:

- If limited by queue_size: `number_of_instances*timeout[min]*sending_queue.queue_size/load_in_DPM` minutes.
- If limited by PVC size: `number_of_instances*PVC_size/(1KB*load_in_DPM)` minutes.

## Assigning Pod to particular Node

### Using NodeSelectors

Kubernetes offers a feature of assigning specific pod to node. Such kind of control is sometimes useful,
whenever you want to ensure that pod will end up on specific node according your requirements like operating system
or connected devices.

#### Binding pods to linux nodes

Using this feature we can bind them to linux nodes.
In order to do that `nodeSelector` has to be used. By default node selectors can be set for below pods:

| component               | key                                                                             |
|-------------------------|---------------------------------------------------------------------------------|
| `fluent-bit`            | `fluent-bit.nodeSelector.kubernetes.io/os`                                      |
| `fluentd`               | `fluentd.events.statefulset.nodeSelector.kubernetes.io/os`                      |
| `fluentd`               | `fluentd.logs.statefulset.nodeSelector.kubernetes.io/os`                        |
| `fluentd`               | `fluentd.metrics.statefulset.nodeSelector.kubernetes.io/os`                     |
| `sumologic`             | `sumologic.setup.job.nodeSelector.kubernetes.io/os`                             |
| `kube-prometheus-stack` | `kube-prometheus-stack.prometheus-node-exporter.nodeSelector.kubernetes.io/os`  |
| `kube-state-metrics`    | `kube-prometheus-stack.kube-state-metrics.nodeSelector.kubernetes.io/os`        |
| `prometheus`            | `kube-prometheus-stack.prometheus.prometheusSpec.nodeSelector.kubernetes.io/os` |
| `otelagent`             | `otelagent.daemonset.nodeSelector.kubernetes.io/os`                             |
| `otelcol`               | `otelcol.deployment.nodeSelector.kubernetes.io/os`                              |
| `otelgateway`           | `otelgateway.deployment.nodeSelector.kubernetes.io/os`                          |
| `otellogs`              | `otellogs.daemonset.nodeSelector.kubernetes.io/os`                              |
| `metadata`              | `metadata.metrics.statefulset.nodeSelector.kubernetes.io/os`                    |
| `metadata`              | `metadata.logs.statefulset.nodeSelector.kubernetes.io/os`                       |

Node selector can be changed via additional parameter in `user-values.yaml`, see an example for Fluent-Bit below:

```yaml
fluent-bit:
  nodeSelector:
    kubernetes.io/os: linux
```

## Parsing log content as json

In order to parse and store log content as json following configuration has to be applied:

:construction: *TODO*, see [the FluentD section](fluent/best-practices.md#parsing-log-content-as-json)
