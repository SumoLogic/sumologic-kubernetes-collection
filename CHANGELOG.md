# Change Log

## v1.0.0
- Expose new configs in `values.yaml` to enable users to configure Fluentd to their liking. See the new `fluentd` section in `values.yaml` for more details.
- Make several changes to `values.yaml` for consistency and understandability:

Old Config | New Config
|:-------- |:--------
`sumologic.eventCollectionEnabled` | `fluentd.events.enabled`
`sumologic.logFormat` | `fluentd.logs.output.logFormat`
`sumologic.flushInterval` | `fluentd.buffer.flushInterval`
`sumologic.numThreads` | `fluentd.buffer.numThreads`
`sumologic.chunkLimitSize` | `fluentd.buffer.chunkLimitSize`
`sumologic.totalLimitSize` | `fluentd.buffer.totalLimitSize`
`sumologic.sourceName` | `fluentd.logs.containers.sourceName`
`sumologic.sourceCategory` | `fluentd.logs.containers.sourceCategory`
`sumologic.sourceCategoryPrefix` | `fluentd.logs.containers.sourceCategoryPrefix`
`sumologic.sourceCategoryReplaceDash` | `fluentd.logs.containers.sourceCategoryReplaceDash`
`sumologic.verifySsl` | `fluentd.verifySsl`
`sumologic.excludeContainerRegex` | `fluentd.logs.containers.excludeContainerRegex`
`sumologic.excludeHostRegex` | `fluentd.logs.containers.excludeHostRegex`
`sumologic.excludeNamespaceRegex` | `fluentd.logs.containers.excludeNamespaceRegex`
`sumologic.excludePodRegex` | `fluentd.logs.containers.excludePodRegex`
`sumologic.fluentdLogLevel` | `fluentd.logLevel`
`sumologic.watchResourceEventsOverrides` | `fluentd.events.watchResourceEventsOverrides`
`sumologic.k8sMetadataFilter` | `fluentd.logs.containers.k8sMetadataFilter`

- Remove some outdated configs in `values.yaml`
  - `sumologic.kubernetesMeta`
  - `sumologic.kubernetesMetaReduce`
  - To preserve the behavior of `kubernetesMeta` or `kubernetesMetaReduce`, we recommend using the `fields` log_format, which by default strips this metadata from the body of the log message.
  - `sumologic.addTimestamp`
  - `sumologic.timestampKey`
  - `sumologic.addStream`
  - `sumologic.addTime`
  - To preserve the behavior of `addTimestamp`, `timestampKey`, `addStream`, and `addtime`, you can use the [record_modifier plugin](https://github.com/repeatedly/fluent-plugin-record-modifier) in the new section of the `values.yaml` file, under `fluentd.logs.containers.extraFilterPluginConf`. For example, to preserve the values of `addTimestamp = true`, `timestampKey = timestamp`, `addStream = false`, `addTime = false`
  ```
  fluentd:
    logs:
      containers:
        extraFilterPluginConf:
          <filter **>
            @type record_modifier
            remove_keys stream,time
            <record>
              timestamp ${time.to_i}
            </record>
          </filter>
  ```
