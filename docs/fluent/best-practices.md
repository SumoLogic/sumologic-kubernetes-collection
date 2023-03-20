# Advanced Configuration / Best Practices

- [Multiline Log Support](#multiline-log-support)
  - [MySQL slow logs example](#mysql-slow-logs-example)
  - [Disable multiline detection](#disable-multiline-detection)
- [Collecting Log Lines Over 16KB (with multiline support)](#collecting-log-lines-over-16kb-with-multiline-support)
  - [Multiline Support](#multiline-support)
- [Collecting logs from /var/log/pods](#collecting-logs-from-varlogpods)
  - [Fluentd tag for /var/log/pods and /var/log/containers](#fluentd-tag-for-varlogpods-and-varlogcontainers)
- [Choosing Fluentd Base Image](#choosing-fluentd-base-image)
- [Fluentd Autoscaling](#fluentd-autoscaling)
  - [CPU resources warning](#cpu-resources-warning)
- [Fluentd File-Based Buffer](#fluentd-file-based-buffer)
  - [Fluentd buffer size for metrics](#fluentd-buffer-size-for-metrics)
- [Excluding Logs From Specific Components](#excluding-logs-from-specific-components)
- [Modifying logs in Fluentd](#modifying-logs-in-fluentd)
- [Split Big Chunks in Fluentd](#split-big-chunks-in-fluentd)
- [Excluding Metrics](#excluding-metrics)
- [Excluding Dimensions](#excluding-dimensions)
- [Add a local file to fluent-bit configuration](#add-a-local-file-to-fluent-bit-configuration)
- [Templating Kubernetes metadata](#templating-kubernetes-metadata)
- [Configure Ignore_Older Config for Fluentbit](#configure-ignore_older-config-for-fluentbit)
- [Adding custom fields](#adding-custom-fields)
- [Using custom Kubernetes API server address](#using-custom-kubernetes-api-server-address)
- [Parsing log content as json](#parsing-log-content-as-json)

## Multiline Log Support

For logs in Docker format by default, we use a regex that matches the first line of multiline logs that start with dates in the following
format: `2019-11-17 07:14:12`.

If your logs have a different date format you can provide a custom regex to detect the first line of multiline logs. See
[collecting multiline logs](https://help.sumologic.com/docs/send-data/reference-information/collect-multiline-logs/) for details on
configuring a boundary regex.

New parsers can be defined under the `fluent-bit.config.customParsers` key in `user-values.yaml` file as follows:

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

This way one can add a parser called `new_multi_line_parser` which matches lines that start with time of the format : `07:14:12`.

To start using the newly defined parser, define it in `Docker_Mode_Parser` parameter in the `Input plugin` configuration of fluent-bit in
`user-values.yaml` under `fluent-bit.config.inputs`:

```
Docker_Mode_Parser new_multi_line_parser
```

The regex used for needs to have at least one named capture group.

For detailed information about parsing container logs please see [here](container-logs.md).

### MySQL slow logs example

For example to detect mulitlines for `slow logs` correctly, ensure that `Fluent Bit` reads `slow log` files and update your configuration
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

### Disable multiline detection

To disable multiline detection, remove the `Docker_Mode_Parser multi_line` setting from Fluent Bit's configuration in
`fluent-bit.config.inputs` property.

Note that to remove this line, the whole value of the `fluent-bit.config.inputs` property must be copied into your `user-values.yaml` file
with that single line removed:

```yaml
fluent-bit:
  config:
    inputs: |
      [INPUT]
          Name                tail
          Path                /var/log/containers/*.log
          Docker_Mode         On
          Tag                 containers.*
          Refresh_Interval    1
          Rotate_Wait         60
          Mem_Buf_Limit       5MB
          Skip_Long_Lines     On
          DB                  /tail-db/tail-containers-state-sumo.db
          DB.Sync             Normal
      [INPUT]
          Name            systemd
          Tag             host.*
          DB              /tail-db/systemd-state-sumo.db
          Systemd_Filter  _SYSTEMD_UNIT=addon-config.service
          Systemd_Filter  _SYSTEMD_UNIT=addon-run.service
          Systemd_Filter  _SYSTEMD_UNIT=cfn-etcd-environment.service
          Systemd_Filter  _SYSTEMD_UNIT=cfn-signal.service
          Systemd_Filter  _SYSTEMD_UNIT=clean-ca-certificates.service
          Systemd_Filter  _SYSTEMD_UNIT=containerd.service
          Systemd_Filter  _SYSTEMD_UNIT=coreos-metadata.service
          Systemd_Filter  _SYSTEMD_UNIT=coreos-setup-environment.service
          Systemd_Filter  _SYSTEMD_UNIT=coreos-tmpfiles.service
          Systemd_Filter  _SYSTEMD_UNIT=dbus.service
          Systemd_Filter  _SYSTEMD_UNIT=docker.service
          Systemd_Filter  _SYSTEMD_UNIT=efs.service
          Systemd_Filter  _SYSTEMD_UNIT=etcd-member.service
          Systemd_Filter  _SYSTEMD_UNIT=etcd.service
          Systemd_Filter  _SYSTEMD_UNIT=etcd2.service
          Systemd_Filter  _SYSTEMD_UNIT=etcd3.service
          Systemd_Filter  _SYSTEMD_UNIT=etcdadm-check.service
          Systemd_Filter  _SYSTEMD_UNIT=etcdadm-reconfigure.service
          Systemd_Filter  _SYSTEMD_UNIT=etcdadm-save.service
          Systemd_Filter  _SYSTEMD_UNIT=etcdadm-update-status.service
          Systemd_Filter  _SYSTEMD_UNIT=flanneld.service
          Systemd_Filter  _SYSTEMD_UNIT=format-etcd2-volume.service
          Systemd_Filter  _SYSTEMD_UNIT=kube-node-taint-and-uncordon.service
          Systemd_Filter  _SYSTEMD_UNIT=kubelet.service
          Systemd_Filter  _SYSTEMD_UNIT=ldconfig.service
          Systemd_Filter  _SYSTEMD_UNIT=locksmithd.service
          Systemd_Filter  _SYSTEMD_UNIT=logrotate.service
          Systemd_Filter  _SYSTEMD_UNIT=lvm2-monitor.service
          Systemd_Filter  _SYSTEMD_UNIT=mdmon.service
          Systemd_Filter  _SYSTEMD_UNIT=nfs-idmapd.service
          Systemd_Filter  _SYSTEMD_UNIT=nfs-mountd.service
          Systemd_Filter  _SYSTEMD_UNIT=nfs-server.service
          Systemd_Filter  _SYSTEMD_UNIT=nfs-utils.service
          Systemd_Filter  _SYSTEMD_UNIT=node-problem-detector.service
          Systemd_Filter  _SYSTEMD_UNIT=ntp.service
          Systemd_Filter  _SYSTEMD_UNIT=oem-cloudinit.service
          Systemd_Filter  _SYSTEMD_UNIT=rkt-gc.service
          Systemd_Filter  _SYSTEMD_UNIT=rkt-metadata.service
          Systemd_Filter  _SYSTEMD_UNIT=rpc-idmapd.service
          Systemd_Filter  _SYSTEMD_UNIT=rpc-mountd.service
          Systemd_Filter  _SYSTEMD_UNIT=rpc-statd.service
          Systemd_Filter  _SYSTEMD_UNIT=rpcbind.service
          Systemd_Filter  _SYSTEMD_UNIT=set-aws-environment.service
          Systemd_Filter  _SYSTEMD_UNIT=system-cloudinit.service
          Systemd_Filter  _SYSTEMD_UNIT=systemd-timesyncd.service
          Systemd_Filter  _SYSTEMD_UNIT=update-ca-certificates.service
          Systemd_Filter  _SYSTEMD_UNIT=user-cloudinit.service
          Systemd_Filter  _SYSTEMD_UNIT=var-lib-etcd2.service
          Max_Entries     1000
          Read_From_Tail  true
```

## Collecting Log Lines Over 16KB (with multiline support)

Docker daemon has a limit of 16KB/line so if a log line is longer than that, it might be truncated in Sumo. To fix this, fluent-bit exposes
a parameter:

```bash
Docker_Mode  On
```

If enabled, the plugin will recombine split Docker log lines before passing them to any parser.

### Multiline Support

To add multiline support to docker mode, you need to follow the [multiline log support](#multiline-log-support) section and assign created
parser to the `Docker_Mode_Parser` parameter in the `Input plugin` configuration of fluent-bit:

```
Docker_Mode_Parser multi_line
```

## Collecting logs from /var/log/pods

In order to collect logs from `/var/log/pods`, please copy full `fluent-bit.config.inputs` section from
[values.yaml](/deploy/helm/sumologic/values.yaml) and change `Path` to `/var/log/pods/*/*/*.log`.

In addition, Fluentd and/or OpenTelemetry configuration should be changed as well.

Please take a look at the following examples which contains all of required changes:

```yaml
fluent-bit:
  config:
    inputs: |
      [INPUT]
          Name                tail
          Path                /var/log/pods/*/*/*.log
          Parser              containerd
          Tag                 containers.*
          Refresh_Interval    1
          Rotate_Wait         60
          Mem_Buf_Limit       5MB
          Skip_Long_Lines     On
          DB                  /tail-db/tail-containers-pods-state-sumo.db
          DB.Sync             Normal
      # ... Rest of fluent-bit configuration comes here

## Fluentd change
fluentd:
  logs:
    containers:
      k8sMetadataFilter:
        ## uses docker_id as alias for uid as it's being used in plugin's code directly
        tagToMetadataRegexp: .+?\.pods\.(?<namespace>[^_]+)_(?<pod_name>[^_]+)_(?<docker_id>(?<uid>[a-f0-9\-]{36}))\.(?<container_name>[^\._]+)\.(?<run_id>\d+)\.log$

## OpenTelemetry change
metadata:
  logs:
    config:
      merge:
        processors:
          attributes/containers:
            actions:
              - action: extract
                key: fluent.tag
                pattern: ^containers\.var\.log\.pods\.(?P<k8s_namespace>[^_]+)_(?P<k8s_pod_name>[^_]+)_(?P<k8s_uid>[a-f0-9\-]{36})\.(?P<k8s_container_name>[^\._]+)\.(?P<k8s_run_id>\d+)\.log$
              - action: delete
                key: k8s_uid
              - action: delete
                key: k8s_run_id
              - action: insert
                key: k8s.pod.name
                from_attribute: k8s_pod_name
              - action: delete
                key: k8s_pod_name
              - action: insert
                key: k8s.namespace.name
                from_attribute: k8s_namespace
              - action: delete
                key: k8s_namespace
              - action: insert
                key: k8s.container.name
                from_attribute: k8s_container_name
              - action: delete
                key: k8s_container_name
```

### Fluentd tag for /var/log/pods and /var/log/containers

[Fluentd tag][fluent_routing] value depends on directory from which logs are scraped:

- `/var/log/pods` is resolved to `containers.var.log.pods.<namespace>_<pod>_<container_id>.<container>.<run_id>.log`
- `/var/log/containers` is resolved to `containers.var.log.containers.<pod>_<namespace>_<container>-<container_id>.log`

e.g. if you want to use additional [filter][fluentd_filter] for container `test-container`, you need to use the following Fluentd
[filter][fluentd_filter] directive header:

- `<filter containers.var.log.pods.*_*_*.test-container.*.log>` for `/var/log/pods`
- `<filter containers.var.log.containers.*_*_test-container-*.log>` for `/var/log/containers`
- `<filter containers.var.log.pods.*_*_*.test-container.*.log containers.var.log.containers.*_*_test-container-*.log>` to support both
  `/var/log/pods` and `/var/log/containers`

[fluentd_filter]: https://docs.fluentd.org/filter
[fluent_routing]: https://docs.fluentd.org/configuration/config-file#interlude-routing

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
    tag: 1.12.2-sumo-6-alpine
```

Go to the [official Sumo Logic's Fluentd image repository](https://gallery.ecr.aws/sumologic/kubernetes-fluentd) to find the latest release
of Fluentd. The Alpine-based releases are the ones with the `-alpine` suffix.

Both Debian-based and Alpine-based images support the same architectures:

- x86-64,
- ARM 32-bit,
- ARM 64-bit.

The source code and the `Dockerfile`s for both images can be found at https://github.com/SumoLogic/sumologic-kubernetes-fluentd.

## Fluentd Autoscaling

We have provided an option to enable autoscaling for both logs and metrics Fluentd statefulsets. This is disabled by default.

Whenever your Fluentd pods CPU consumption is near the limit you could experience a
[delay in data ingestion or even a data loss](/docs/monitoring-lag.md) in extreme situations. In such cases you should enable the
autoscaling.

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

### CPU resources warning

When enabling the Fluentd Autoscaling please make sure to set Fluentd's `resources.requests.cpu` properly. Because of Fluentd's single
threaded nature it rarely consumes more than `1000m` CPU (1 CPU core).

For example setting `resources.requests.cpu=2000m` and the `autoscaling.targetCPUUtilizationPercentage=50` means that autoscaling will
increase the number of application pods only if average CPU usage across all application pods in statefulset or daemonset is more than
`1000m`. This combined with Fluentd's usage of around `1000m` at most will result in autoscaling not working properly.

**For this reason we suggest to set the Fluentd's `resources.requests.cpu=1000m` or less when using autoscaling.**

## Fluentd File-Based Buffer

Starting with `v2.0.0` we're using file-based buffer for Fluentd instead of less reliable in-memory buffer.

The buffer configuration can be set in the `user-values.yaml` file under the `fluentd` key as follows:

```yaml
fluentd:
  ## Persist data to a persistent volume; When enabled, fluentd uses the file buffer instead of memory buffer.
  persistence:
    ## After changing this value please follow steps described in:
    ## https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/docs/fluentd-persistence.md
    enabled: true
```

After changing Fluentd persistence setting (enable or disable) follow steps described in [Fluentd Persistence](fluentd-persistence.md).

Additional buffering and flushing parameters can be added in the `extraConf`, in the `fluentd` buffer section.

```yaml
fluentd:
  ## Option to specify the Fluentd buffer as file/memory.
  buffer:
    type: "file"
    extraConf: |-
      retry_exponential_backoff_base 2s
```

We have defined several file paths where the buffer chunks are stored. These can be observed under `fluentd.buffer.filePaths` key in
`values.yaml`.

Once the config has been modified in the `user-values.yaml` file you need to run the `helm upgrade` command to apply the changes.

```bash
helm upgrade collection sumologic/sumologic --reuse-values -f user-values.yaml --force
```

See the following links to official Fluentd buffer documentation:

- https://docs.fluentd.org/configuration/buffer-section
- https://docs.fluentd.org/buffer/file

### Fluentd buffer size for metrics

Should you have any connectivity problems, depending on the buffer size your setup will be able to survive for a given amount of time
without a data loss, delivering the data later when everything is operational again.

The Fluentd buffer size is controlled by two major parameters - the size of the persistent volume in Kubernetes, and the maximum size of the
buffer on disk. Both need to be adjusted if you want to buffer more (or less) data.

For example:

```yaml
fluentd:
  ## Persist data to a persistent volume; When enabled, fluentd uses the file buffer instead of memory buffer.
  persistence:
    ## After changing this value please follow steps described in:
    ## https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/docs/fluentd-persistence.md
    enabled: true
    size: 20Gi
  buffer:
    ## totalLimitSize should be multiplication of `chunkLimitSize`, `queueChunkLimitSize` and number of filePath (maximum of `logs`, `metrics`, `traces`, `events`)
    totalLimitSize: "20G"
```

The `fluentd.buffer` section contains other settings for Fluentd buffering. Please study relevant documentation for `chunkLimitSize` and
`queueChunkLimitSize`:

- https://docs.fluentd.org/configuration/buffer-section
- https://docs.fluentd.org/buffer/file

For bigger chunks, we recommend to use [split and retry mechanism](#split-big-chunks-in-fluentd) included into sumologic output plugin.

To calculate this time you need to know how much data you send. For the calculations below we made an assumption that a single metric data
point is around 1 kilobyte in size, including metadata. This assumption is based on the average data we ingest. By default, for file based
buffering we use gzip compression which gives us around 3:1 compress ratio.

That results in `1 DPM` (Data Points per Minute) using around `333 bytes of buffer`. That is `333 kilobytes for 1 thousand DPM` and
`333 megabytes for 1 million DPM`. In other words - storing a million data points will use a 333 megabytes of buffer every minute.

This buffer size can be spread between multiple Fluentd instances. To have the best results you should use the metrics load balancing which
can be enabled by using the following setting: `sumologic.metrics.remoteWriteProxy.enabled=true`. It enables the remote write proxy where
nginx is being used to forward data from Prometheus to Fluentds. We strongly recommend using this setting as in case of uneven load your
buffer storage is as big as single Fluentd instance buffer. Unfortunately even with `remoteWriteProxy` enabled you might experience uneven
load. Because of that we also `recommend to make your buffers twice the calculated size`.

The formula to calculate the buffering time:

```
minutes = (PV size in bytes * Fluentd instances) / (DPM * 333 bytes)
```

Example 1: My cluster sends 10 thousand DPM to Sumo. I'm using default 10 gb of buffer size. I'm also using 3 Fluentd instances. That gives
me 30 gb of buffers in total (3 \* 10 gb). I'm using 3.33 mb per minute. My setup should be able to hold data for 9000 minutes, that is 150
hours or 6.25 days. We recommend treating this as 4500 minutes, that is 75 hours or 3.12 days of buffer.

Example 2: My cluster sends 1 million DPM to Sumo. I'm using 20 gb of buffer size. I'm using 20 Fluentd instances. I have 400 gb of buffers
in total (20 \* 20 gb). I'm using 333 mb of buffer every minute. My setup should be able to hold data for around 1200 minutes, that is 20
hours. We recommend treating this as 600 minutes, that is 10 hours of buffer.

## Excluding Logs From Specific Components

You can exclude specific logs from specific components from being sent to Sumo Logic by specifying the following parameters either in the
`user-values.yaml` file or the `helm install` command.

```
excludeContainerRegex
excludeHostRegex
excludeNamespaceRegex
excludePodRegex
```

- This is Ruby regex, so all ruby regex rules apply. Unlike regex in the Sumo collector, you do not need to match the entire line. When
  doing multiple patterns, put them inside of parentheses and pipe separate them.

- For things like pods and containers you will need to use a star at the end because the string is dynamic. Example:

  ```yaml
  excludePodRegex: "(dashboard.*|sumologic.*)"
  ```

- For things like namespace you won’t need to use a star at the end since there is no dynamic string. Example:

  ```yaml
  excludeNamespaceRegex: “(sumologic|kube-public)”
  ```

If you wish to exclude logs based on the content of the log message, you can leverage the fluentd `grep` filter plugin. We expose
`fluentd.logs.containers.extraFilterPluginConf` which allows you to inject additional filter plugins to process data. For example suppose
you want to exclude the following log messages:

```
.*connection accepted from.*
.*authenticated as principal.*
.*client metadata from.*
```

You can simply add the following to your `user-values.yaml`:

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

You can find more information on the `grep` filter plugin in the [fluentd documentation](https://docs.fluentd.org/filter/grep).

## Modifying logs in Fluentd

You can redact log messages in order to e.g. prevent sending sensitive data like passwords.

In order to do that [record_transformer filter][record_transformer] can be used. Please consider the following configuration:

```yaml
fluentd:
  logs:
    containers:
      extraFilterPluginConf: |-
        # Apply to all test-container containers
        <filter containers.var.log.pods.*_*_*.test-container.*.log containers.var.log.containers.*_*_test-container-*.log>
          @type record_transformer
          enable_ruby
          <record>
            # Replace `Password: <pass>` with `Password: ***`
            log ${record["log"].gsub(/Password: (.*)/, 'Password: ***')}
            # Replace kubernetes['namespace_name'] with 'REDACTED'
            # if namespace_name exists in record['kubernetes'], then change value of it and then return modified record['kubernetes'] to assign as kubernetes
            kubernetes = ${if record['kubernetes'].has_key?('namespace_name'); record['kubernetes']['namespace_name'] = "REDACTED"; end; record['kubernetes']}
          </record>
        </filter>
```

It is going to replace all `Password: <pass>` occurence in logs with `Password: ***` and replace namespace to `REDACTED` for
[all containers](#fluentd-tag-for-varlogpods-and-varlogcontainers) named `test-container`.

An example log before entering the `extraFilterPluginConf` section is presented below:

```json
{
  "stream": "stdout",
  "logtag": "F",
  "log": "Password: 123456",
  "docker": {
    "container_id": "a1acfd70-c8d1-456b-95dd-515f1256906f"
  },
  "kubernetes": {
    "container_name": "test-container",
    "namespace_name": "multiline-logs-generator",
    "pod_name": "multiline-logs-generator",
    "pod_id": "a1acfd70-c8d1-456b-95dd-515f1256906f",
    "host": "sumologic-kubernetes-collection",
    "labels": {
      "example": "multiline-logs-generator"
    },
    "master_url": "https://10.152.183.1:443/api",
    "namespace_id": "3e6d679e-f9f4-4333-966c-a8354457f8f4",
    "namespace_labels": {
      "kubernetes.io/metadata.name": "multiline-logs-generator"
    }
  }
}
```

[record_transformer]: https://docs.fluentd.org/filter/record_transformer

## Split Big Chunks in Fluentd

In order to support big chunks we have added split and retry mechanism into out output plugin. It is recommended to use it in order to
process big chunks. It also fixes [logs duplication](troubleshoot-collection.md#duplicated-logs). Please consider the following
configuration in order to use it:

```yaml
fluentd:
  logs:
    output:
      extraConf: |-
        ## use plugin's retry mechanisms, which uses exponential algorithm
        use_internal_retry true
        ## sets minimum retry interval to 5s
        retry_min_interval 5s
        ## sets maximum retry interval to 10m
        retry_max_interval 10m
        ## timeout after 72h
        retry_timeout 72h
        ## do not limit number of requests
        retry_max_times 0
        ## set maximum request size to 1m to avoid timeouts
        max_request_size 1m
  metrics:
    extraOutputConf: |-
      ## use plugin's retry mechanisms, which uses exponential algorithm
      use_internal_retry true
      ## sets minimum retry interval to 5s
      retry_min_interval 5s
      ## sets maximum retry interval to 10m
      retry_max_interval 10m
      ## timeout after 72h
      retry_timeout 72h
      ## do not limit number of requests
      retry_max_times 0
      # Set maximum request size to 16m to avoid timeouts
      max_request_size 16m
```

## Excluding Metrics

You can exclude metrics by any tag in Fluentd. For example to filter out metrics from `sumologic` namespace, you can use following
configuration:

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

## Excluding Dimensions

You can also exclude dimensions in Fluentd using [record_transformer plugin][record_transformer plugin]. For example to filter out
`pod_labels_operator.prometheus.io/name` and `cluster` dimensions, you can use the following configuration:

```yaml
fluentd:
  metrics:
    extraFilterPluginConf: |-
      <filter **>
        @type record_transformer
        remove_keys $['pod_labels']['operator.prometheus.io/name'],$.cluster
      </filter>
```

Example metric structure which is an input for `extraFilterPluginConf` is presented in the following snippet:

```json
{
  "@metric": "container_memory_working_set_bytes",
  "cluster": "my-cluster",
  "container": "thanos-sidecar",
  "endpoint": "https-metrics",
  "image": "public.ecr.aws/sumologic/thanos:v0.23.1",
  "instance": "10.0.2.15:10250",
  "job": "kubelet",
  "metrics_path": "/metrics/cadvisor",
  "namespace": "sumologic",
  "node": "sumologic-kubernetes-collection",
  "pod": "prometheus-collection-kube-prometheus-prometheus-0",
  "prometheus": "sumologic/collection-kube-prometheus-prometheus",
  "prometheus_replica": "prometheus-collection-kube-prometheus-prometheus-0",
  "@timestamp": 1645772362877,
  "@value": 21032960,
  "prometheus_service": "collection-kube-prometheus-kubelet",
  "pod_labels": {
    "app": "prometheus",
    "controller-revision-hash": "prometheus-collection-kube-prometheus-prometheus-5f68598c76",
    "operator.prometheus.io/name": "collection-kube-prometheus-prometheus",
    "operator.prometheus.io/shard": "0",
    "prometheus": "collection-kube-prometheus-prometheus",
    "statefulset.kubernetes.io/pod-name": "prometheus-collection-kube-prometheus-prometheus-0"
  },
  "service": "collection-kube-prometheus-prometheus_prometheus-operated",
  "statefulset": "prometheus-collection-kube-prometheus-prometheus"
}
```

[record_transformer plugin]: https://docs.fluentd.org/filter/record_transformer

## Add a local file to fluent-bit configuration

If you want to capture container logs to a container that writes locally, you will need to ensure the logs get mounted to the host so
fluent-bit can be configured to capture from the host.

Example: In `user-values.yaml` in the `fluent-bit.config.input` section, you have to add a new `INPUT` specifying the file path (retaining
the remaining part of `input` config), e.g.:

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

**Notice:** In some cases Tailing Sidecar Operator may help in getting logs not available on standard output (STDOUT), please see section
[Get logs not available on stdout](/docs/best-practices.md#get-logs-not-available-on-stdout).

## Templating Kubernetes metadata

The following Kubernetes metadata is available for string templating:

| String template  | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `%{namespace}`   | Namespace name                                          |
| `%{pod}`         | Full pod name (e.g. `travel-products-4136654265-zpovl`) |
| `%{pod_name}`    | Friendly pod name (e.g. `travel-products`)              |
| `%{pod_id}`      | The pod's uid (a UUID)                                  |
| `%{container}`   | Container name                                          |
| `%{source_host}` | Host                                                    |
| `%{label:foo}`   | The value of label `foo`                                |

## Configure Ignore_Older Config for Fluentbit

We have observed that the `Ignore_Older` config does not work when `Multiline` is set to `On`. Default config:

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

Please make the below changes to the `INPUT` section to turn off `Multiline` and add a `docker` parser to parse the time for `Ignore_Older`
functionality to work properly.

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

[sumo_add_fields]: https://help.sumologic.com/docs/manage/fields/#add-field

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

## Using custom Kubernetes API server address

In order to change API server address, the following configurations can be used.

```yaml
fluentd:
  apiServerUrl: http://my-custom-k8s.api:12345
```

## Parsing log content as json

In order to parse and store log content as json following configuration has to be applied:

```yaml
fluentd:
  logs:
    containers:
      extraOutputPluginConf: |-
        <filter **>
          @type record_modifier
          <record>
            _sumo_metadata ${record["_sumo_metadata"][:log_format] = 'json_merge'; record["_sumo_metadata"]}
          </record>
        </filter>
```
