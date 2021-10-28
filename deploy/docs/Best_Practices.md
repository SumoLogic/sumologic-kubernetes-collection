# Advanced Configuration / Best Practices

- [Multiline Log Support](#multiline-log-support)
  - [MySQL slow logs example](#mysql-slow-logs-example)
- [Collecting Log Lines Over 16KB (with multiline support)](#collecting-log-lines-over-16kb-with-multiline-support)
  - [Multiline Support](#multiline-support)
- [Choosing Fluentd Base Image](#choosing-fluentd-base-image)
- [Fluentd Autoscaling](#fluentd-autoscaling)
- [Fluentd File-Based Buffer](#fluentd-file-based-buffer)
- [Excluding Logs From Specific Components](#excluding-logs-from-specific-components)
- [Excluding Metrics](#excluding-metrics)
- [Add a local file to fluent-bit configuration](#add-a-local-file-to-fluent-bit-configuration)
- [Filtering Prometheus Metrics by Namespace](#filtering-prometheus-metrics-by-namespace)
- [Modify the Log Level for Falco](#modify-the-log-level-for-falco)
- [Overriding metadata using annotations](#overriding-metadata-using-annotations)
  - [Overriding source category with pod annotations](#overriding-source-category-with-pod-annotations)
- [Excluding data using annotations](#excluding-data-using-annotations)
  - [Including subsets of excluded data](#including-subsets-of-excluded-data)
- [Templating Kubernetes metadata](#templating-kubernetes-metadata)
  - [Missing labels](#missing-labels)
- [Configure Ignore_Older Config for Fluentbit](#configure-ignore_older-config-for-fluentbit)
- [Disable logs, metrics, or falco](#disable-logs-metrics-or-falco)
- [Load Balancing Prometheus traffic between Fluentds](#load-balancing-prometheus-traffic-between-fluentds)
- [Changing scrape interval for Prometheus](#changing-scrape-interval-for-prometheus)
- [Get logs not available on stdout](#get-logs-not-available-on-stdout)
- [Adding custom fields](#adding-custom-fields)

## Multiline Log Support

By default, we use a regex that matches the first line of multiline logs
that start with dates in the following format: `2019-11-17 07:14:12`.

If your logs have a different date format you can provide a custom regex to detect
the first line of multiline logs.
See [collecting multiline logs](https://help.sumologic.com/?cid=49494) for details
on configuring a boundary regex.

New parsers can be defined under the `fluent-bit.config.customParsers` key in
`values.yaml` file as follows:

```yaml
fluent-bit:
  config:
    customParsers: |
      [PARSER]
          Name        multi_line
          Format      regex
          Regex       (?<log>^{"log":"\[?\d{4}-\d{1,2}-\d{1,2}.\d{2}:\d{2}:\d{2}.*)
      [PARSER]
          Name        new_multi_line_parser
          Format      regex
          Regex       (?<log>^{"log":"\d{2}:\d{2}:\d{2}.*)
```

This way one can add a parser called `new_multi_line_parser` which matches lines
that start with time of the format : `07:14:12`.

To start using the newly defined parser, define it in `Docker_Mode_Parser` parameter
in the `Input plugin` configuration of fluent-bit in `values.yaml` under
`fluent-bit.config.inputs`:

```
Docker_Mode_Parser new_multi_line_parser
```

The regex used for needs to have at least one named capture group.

### MySQL slow logs example

For example to detect mulitlines for `slow logs` correctly,
ensure that `Fluent Bit` reads `slow log` files and update your configuration
with following snippet:

```
fluent-bit:
  config:
    customParsers: |
      [PARSER]
          Name        multi_line
          Format      regex
          Regex       (?<log>^{"log":"(\d{4}-\d{1,2}-\d{1,2}.\d{2}:\d{2}:\d{2}.*|#\sTime:\s+.*))
```

## Collecting Log Lines Over 16KB (with multiline support)

Docker daemon has a limit of 16KB/line so if a log line is longer than that,
it might be truncated in Sumo.
To fix this, fluent-bit exposes a parameter:

``` bash
Docker_Mode  On
```

If enabled, the plugin will recombine split Docker log lines before passing them to any parser.

### Multiline Support

To add multiline support to docker mode, you need to follow the
[multiline log support](#multiline-log-support) section and assign created parser
to the `Docker_Mode_Parser` parameter in the `Input plugin` configuration of fluent-bit:

```
Docker_Mode_Parser multi_line
```

## Choosing Fluentd Base Image

Historically, the Fluentd container image used with the collection was based on Debian Linux distribution.

Currently, an Alpine-based image is also available and can be used instead of the Debian-based image.

The Debian-based image is the default, so you do not need to change anything to use it.

To use an Alpine-based image with the collection, specify an Alpine image's tag in `fluentd.image.tag` chart property:

```yaml
fluentd:
  image:
    tag: <Fluentd-release>-alpine
```

For example:

```yaml
fluentd:
  image:
    tag: 1.12.2-sumo-5-alpine
```

Go to the [official Sumo Logic's Fluentd image repository](https://gallery.ecr.aws/sumologic/kubernetes-fluentd)
to find the latest release of Fluentd.
The Alpine-based releases are the ones with the `-alpine` suffix.

Both Debian-based and Alpine-based images support the same architectures:

- x86-64,
- ARM 32-bit,
- ARM 64-bit.

The source code and the `Dockerfile`s for both images can be found at https://github.com/SumoLogic/sumologic-kubernetes-fluentd.

## Fluentd Autoscaling

We have provided an option to enable autoscaling for both logs and metrics Fluentd statefulsets.
This is disabled by default.

To enable autoscaling for Fluentd:

- Enable metrics-server dependency

  Note: If metrics-server is already installed, this step is not required.

  ```yaml
  ## Configure metrics-server
  ## ref: https://github.com/bitnami/charts/tree/master/bitnami/metrics-server/values.yaml
  metrics-server:
    enabled: true
  ```

- Allow metrics-server communication with kubelet for [KOPS](https://github.com/kubernetes/kops)

  Note: This step is required only for KOPS clusters

  ```yaml
  ## This goes to the kops cluster configuration file
  kubelet:
     # ...
     ## Enable webhook authorization for KOPS cluster
     ## rel: https://github.com/kubernetes/kops/issues/7200
     authenticationTokenWebhook: true
     authorizationMode: Webhook
  ```

- Enable autoscaling for Logs Fluentd statefulset

  ```yaml
  fluentd:
    logs:
      ## Option to turn autoscaling on for fluentd and specify metrics for HPA.
      autoscaling:
        enabled: true
  ```

- Enable autoscaling for Metrics Fluentd statefulset

  ```yaml
  fluentd:
    metrics:
      ## Option to turn autoscaling on for fluentd and specify metrics for HPA.
      autoscaling:
        enabled: true
  ```

## Fluentd File-Based Buffer

Starting with `v2.0.0` we're using file-based buffer for Fluentd instead of less
reliable in-memory buffer.

The buffer configuration can be set in the `values.yaml` file under the `fluentd`
key as follows:

```yaml
fluentd:
  ## Persist data to a persistent volume; When enabled, fluentd uses the file buffer instead of memory buffer.
  persistence:
    ## After changing this value please follow steps described in:
    ## https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/deploy/docs/FluentdPersistence.md
    enabled: true
```

After changing Fluentd persistence setting (enable or disable) follow steps described in [Fluentd Persistence](FluentdPersistence.md).

Additional buffering and flushing parameters can be added in the `extraConf`,
in the `fluentd` buffer section.

```yaml
fluentd:
## Option to specify the Fluentd buffer as file/memory.
   buffer:
     type : "file"
     extraConf: |-
       retry_exponential_backoff_base 2s
```

We have defined several file paths where the buffer chunks are stored.
These can be observed under `fluentd.buffer.filePaths` key in `values.yaml`.

Once the config has been modified in the `values.yaml` file you need to run
the `helm upgrade` command to apply the changes.

```bash
helm upgrade collection sumologic/sumologic --reuse-values -f values.yaml --force
```

See the following links to official Fluentd buffer documentation:

- https://docs.fluentd.org/configuration/buffer-section
- https://docs.fluentd.org/buffer/file

## Excluding Logs From Specific Components

You can exclude specific logs from specific components from being sent to Sumo Logic
by specifying the following parameters either in the `values.yaml` file or the `helm install` command.

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

If you wish to exclude logs based on the content of the log message, you can leverage
the fluentd `grep` filter plugin.
We expose `fluentd.logs.containers.extraFilterPluginConf` which allows you to inject
additional filter plugins to process data.
For example suppose you want to exclude the following log messages:

```
.*connection accepted from.*
.*authenticated as principal.*
.*client metadata from.*
```

In your values.yaml, you can simply add the following to your `values.yaml`:

```yaml
fluentd:
  logs:
    containers:
      extraFilterPluginConf: |-
        <filter containers.**>
          @type grep
          <exclude>
            key log
            pattern /(.*connection accepted from.*|.*authenticated as principal.*|.*client metadata from.*)/
          </exclude>
        </filter>
```

You can find more information on the `grep` filter plugin in the
[fluentd documentation](https://docs.fluentd.org/filter/grep).
Refer to our [documentation](v1_conf_examples.md) for other examples of how you can
customize the fluentd pipeline.

## Excluding Metrics

You can filter out metrics directly in promethus using [this documentation](additional_prometheus_configuration.md#filter-metrics).

You can also exclude metrics by any tag in Fluentd.
For example to filter out metrics from `sumologic` namespace, you can use following configuration:

```yaml
fluentd:
  metrics:
    extraFilterPluginConf: |-
      <filter **>
        @type grep
          <exclude>
            key namespace
            pattern /^sumologic$/
          </exclude>
      </filter>
```

## Add a local file to fluent-bit configuration

If you want to capture container logs to a container that writes locally,
you will need to ensure the logs get mounted to the host so fluent-bit can be
configured to capture from the host.

Example:
In `values.yaml` in the `fluent-bit.config.input` section, you have to add
a new `INPUT` specifying the file path (retaining the remaining part of `input`
config), e.g.:

```yaml
fluent-bit:
  config:
    # ...
    inputs: |-
      # Copy original fluent-bit.config.inputs here
      # ...
      [INPUT]
          Name        tail
          Path        /var/log/syslog
```

Reference: https://docs.fluentbit.io/manual/pipeline/inputs/tail#configuration-file

**Notice:** In some cases Tailing Sidecar Operator may help in getting logs not available on standard output (STDOUT),
please see section [Get logs not available on stdout](#get-logs-not-available-on-stdout).

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
     - url: http://collection-sumologic.sumologic.svc.cluster.local:9888/prometheus.metrics
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

To modify the default log level for Falco, edit the following section in the values.yaml file.
Available log levels can be found in Falco's documentation here: https://falco.org/docs/configuration/.

```yaml
falco:
  ## Set the enabled flag to false to disable falco.
  enabled: true
  #ebpf:
  #  enabled: true
  falco:
    jsonOutput: true
    loglevel: debug
```

## Overriding metadata using annotations

You can use [Kubernetes annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
to override some metadata and settings per pod.

- `sumologic.com/format` overrides the value of the `fluentd.logs.output.logFormat` property
- `sumologic.com/sourceCategory` overrides the value of the `fluentd.logs.containers.sourceCategory` property
- `sumologic.com/sourceCategoryPrefix` overrides the value of the `fluentd.logs.containers.sourceCategoryPrefix` property
- `sumologic.com/sourceCategoryReplaceDash` overrides the value of the `fluentd.logs.containers.sourceCategoryReplaceDash`
  property
- `sumologic.com/sourceName` overrides the value of the `fluentd.logs.containers.sourceName` property

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

## Configure Ignore_Older Config for Fluentbit

We have observed that the  `Ignore_Older` config does not work when `Multiline` is set to `On`.
Default config:

```
    [INPUT]
        Name             tail
        Path             /var/log/containers/*.log
        Multiline        On
        Parser_Firstline multi_line
        Tag              containers.*
        Refresh_Interval 1
        Rotate_Wait      60
        Mem_Buf_Limit    5MB
        Skip_Long_Lines  On
        DB               /tail-db/tail-containers-state-sumo.db
        DB.Sync          Normal
```

Please make the below changes to the `INPUT` section to turn off `Multiline` and
add a `docker` parser to parse the time for `Ignore_Older` functionality to work properly.

<pre>
[INPUT]
    Name             tail
    Path             /var/log/containers/*.log
    <b>Multiline        Off</b>
    Parser_Firstline multi_line
    Tag              containers.*
    Refresh_Interval 1
    Rotate_Wait      60
    Mem_Buf_Limit    5MB
    Skip_Long_Lines  On
    DB               /tail-db/tail-containers-state-sumo.db
    DB.Sync          Normal
    <b>Ignore_Older     24h</b>
    <b>Parser           Docker</b>
</pre>

Ref: https://docs.fluentbit.io/manual/pipeline/inputs/tail

## Disable logs, metrics, or falco

If you want to disable the collection of logs, metrics, or falco, make the below changes
respectively in the `values.yaml` file and run the `helm upgrade` command.

| parameter                   | value | function                   |
|-----------------------------|-------|----------------------------|
| `sumologic.logs.enabled`    | false | disable logs collection    |
| `sumologic.metrics.enabled` | false | disable metrics collection |
| `falco.enabled`             | false | disable falco              |

## Load Balancing Prometheus traffic between Fluentds

Equal utilization of the Fluentd pods is important for collection process.
If Fluentd pod is under high pressure, incoming connections can be handled with some delay.
To avoid backpressure, `remote_timeout` configuration options for Prometheus' `remote_write` can be used.
By default this is `30s`, which means that Prometheus is going to wait such amount of time
for connection to specific fluentd before trying to reach another.
This significantly decreases performance and can lead to the Prometheus memory issues,
so we decided to override it with `5s`.

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      additionalScrapeConfigs:
        - #...
          remoteTimeout: 5s
```

**NOTE** We observed that changing this value increases metrics loss during prometheus resharding,
but the traffic is much better balanced between Fluentds and Prometheus is more stable in terms of memory.

## Changing scrape interval for Prometheus

Default scrapeInterval for collection is `30s`. This is the recommended value which ensures that all of Sumo Logic dashboards
are filled up with proper data.

To change it, you can use following configuration:

```yaml
kube-prometheus-stack:  # For values.yaml
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

- Enable Tailing Sidecar Operator by modifying `values.yaml`:

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

In order to add custom fields to container logs, the following configuration has to be applied:

```yaml
fluentd:
  logs:
    containers:
      extraFilterPluginConf: |
        <filter **>
          @type record_modifier
          <record>
            _sumo_metadata ${{:_fields => "<DEFINITION OF CUSTOM FIELDS>"}}
          </record>
        </filter>
      extraOutputPluginConf: |
        <filter **>
          @type record_modifier
          <record>
            _sumo_metadata ${record["_sumo_metadata"][:fields] = "#{record["_sumo_metadata"][:fields]},#{record["_sumo_metadata"][:_fields]}"; record["_sumo_metadata"]}
          </record>
        </filter>
```

where `<DEFINITION OF CUSTOM FIELDS>` has to be `key1=value1,key2=value2,...` formatted string.

**NOTE** Do not forget to [add field in Sumo Logic service][sumo_add_fields]

[sumo_add_fields]: https://help.sumologic.com/Manage/Fields#add-field

Please consider the following configuration which adds `container_image` from kubernetes enrichment.

```yaml
fluentd:
  logs:
    containers:
      extraFilterPluginConf: |
        <filter **>
          @type record_modifier
          <record>
            _sumo_metadata ${{:_fields => "container_image=#{record["kubernetes"]["container_image"]}"}}
          </record>
        </filter>
      extraOutputPluginConf: |
        <filter **>
          @type record_modifier
          <record>
            _sumo_metadata ${record["_sumo_metadata"][:fields] = "#{record["_sumo_metadata"][:fields]},#{record["_sumo_metadata"][:_fields]}"; record["_sumo_metadata"]}
          </record>
        </filter>
```
