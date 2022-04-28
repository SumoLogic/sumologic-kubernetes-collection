# Comparison of Fluentd and Opentelemetry Collector functionality

- [Sumologic supported Fluentd plugins](#sumologic-supported-fluentd-plugins)
  - [Sumologic Output Plugin](#sumologic-output-plugin)
  - [fluent-plugin-datapoint](#fluent-plugin-datapoint)
  - [fluent-plugin-protobuf](#fluent-plugin-protobuf)
  - [fluent-plugin-prometheus-format](#fluent-plugin-prometheus-format)
  - [fluent-plugin-kubernetes-sumologic](#fluent-plugin-kubernetes-sumologic)
    - [sanitized pod name](#sanitized-pod-name)
  - [fluent-plugin-kubernetes-metadata-filter](#fluent-plugin-kubernetes-metadata-filter)
  - [fluent-plugin-enhance-k8s-metadata](#fluent-plugin-enhance-k8s-metadata)
  - [fluent-plugin-events](#fluent-plugin-events)
- [Configuration by pipelines](#configuration-by-pipelines)
  - [Events](#events)
  - [Metrics](#metrics)
  - [Logs](#logs)
  - [Other](#other)

## Sumologic supported Fluentd plugins

### Sumologic Output Plugin

| [Fluentd configuration option][fluentd_output_plugin] | Opentelemetry Collector                                                                                                         |
|-------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| `data_type`                                           | Defined by pipeline type (`service.pipelines`). [See basic configuration documentation][otelcol_basic_confg]                    |
| `endpoint`                                            | [exporters.sumologic.endpoint][otelcol_sumologic_config]                                                                        |
| `verify_ssl`                                          | [exporters.sumologic.tls.insecure_skip_verify][otelocl_tls_config]                                                              |
| `source_category`                                     | [processors.source.source_category][otelcol_source_config]. Placeholders format changed to `%{}`.                               |
| `source_name`                                         | [processors.source.source_name][otelcol_source_config]. Placeholders format changed to `%{}`.                                   |
| `source_name_key`                                     | Not supported. Use predefined attribute in [processors.source.source_name][otelcol_source_config]. For example `%{_sourceName}` |
| `source_host`                                         | [processors.source.source_host][otelcol_source_config]. Placeholders format changed to `%{}`.                                   |
| `log_format`                                          | [exporters.sumologic.log_format][otelcol_sumologic_config] (`json_merge` and `fields` formats are not supported)                |
| `log_key`                                             | [exporters.sumologic.json_logs.log_key][otelcol_sumologic_config]                                                               |
| `open_timeout`                                        | [exporters.sumologic.timeout][otelcol_sumologic_config] (doesn't differentiate between `open` and `send`)                       |
| `send_timeout`                                        | [exporters.sumologic.timeout][otelcol_sumologic_config] (doesn't differentiate between `open` and `send`)                       |
| `add_timestamp`                                       | [exporters.sumologic.json_logs.add_timestamp][otelcol_sumologic_config]                                                         |
| `timestamp_key`                                       | [exporters.sumologic.json_logs.timestamp_key][otelcol_sumologic_config]                                                         |
| `proxy_uri`                                           | [environment variables][otelcol_proxy]                                                                                          |
| `metric_data_format`                                  | [exporters.sumologic.metric_format][otelcol_sumologic_config]                                                                   |
| `disable_cookies`                                     | Cookies are not used in Opentelemetry Collector                                                                                 |
| `compress`                                            | [exporters.sumologic.compress_encoding][otelcol_sumologic_config] set to `""`                                                   |
| `compress_encoding`                                   | [exporters.sumologic.compress_encoding][otelcol_sumologic_config]                                                               |
| `custom_fields`                                       | [Resource processor][resource_processor]                                                                                        |
| `custom_dimensions`                                   | [Resource processor][resource_processor]                                                                                        |

Additional behavior:

| Description                                                                                                    | Opentelemetry Collector                                                                                                                                   |
|----------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [record[_sumo_metadata][source_name]][source_name_precedence] taking precedence over `source_name`             | Can be achieved by separate pipelines                                                                                                                     |
| [record[_sumo_metadata][source_host]][source_host_precedence] taking precedence over `source_host`             | Can be achieved by separate pipelines                                                                                                                     |
| [record[_sumo_metadata][source_category]][source_category_precedence] taking precedence over `source_category` | Can be achieved by separate pipelines                                                                                                                     |
| [record[_sumo_metadata][fields]][fields_base] being base for fields                                            | Can be achieved using [resource processor][resource_processor] and separate pipelines |

[fields_base]: https://github.com/SumoLogic/fluentd-output-sumologic/blob/1.7.2/lib/fluent/plugin/out_sumologic.rb#L284-L285
[fluentd_output_plugin]: https://github.com/sumologic/fluentd-output-sumologic/tree/1.7.2#configuration
[otelcol_basic_confg]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.49.0-sumo-0/docs/Configuration.md#basic-configuration
[otelcol_proxy]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.49.0-sumo-0/docs/Configuration.md#proxy-support
[otelcol_source_config]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/sourceprocessor#config
[otelcol_sumologic_config]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.49.0-sumo-0/pkg/exporter/sumologicexporter/README.md#sumo-logic-exporter
[otelocl_tls_config]: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.47.0/config/configtls/README.md#tls--mtls-configuration
[resource_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.47.0/processor/resourceprocessor#resource-processor
[source_category_precedence]: https://github.com/SumoLogic/fluentd-output-sumologic/blob/1.7.2/lib/fluent/plugin/out_sumologic.rb#L278-L279
[source_host_precedence]: https://github.com/SumoLogic/fluentd-output-sumologic/blob/1.7.2/lib/fluent/plugin/out_sumologic.rb#L281-L282
[source_name_precedence]: https://github.com/SumoLogic/fluentd-output-sumologic/blob/1.7.2/lib/fluent/plugin/out_sumologic.rb#L275-L276

### fluent-plugin-datapoint

In order to receive prometheus data and for their initial processing [telegrafreceiver][telegrafreceiver] is being used.
It should cover [fluent-plugin-datapoint][fluent_plugin_datapoint] functionality and more.

[fluent_plugin_datapoint]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-datapoint
[telegrafreceiver]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/receiver/telegrafreceiver

### fluent-plugin-protobuf

In order to receive prometheus data and for their initial processing [telegrafreceiver][telegrafreceiver] is being used.
It should cover [fluent_plugin_protobuf][fluent_plugin_protobuf] functionality and more.

[fluent_plugin_protobuf]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-protobuf
[telegrafreceiver]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/receiver/telegrafreceiver

### fluent-plugin-prometheus-format

| [Fluentd configuration option][fluent_plugin_prometheus_format] | Opentelemetry Collector                                                                                   |
|-----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| [relabel][prom_form_relabel]                                    | Use [groupbyattrs][groupbyattrs_processor] and [resourceprocessor][resource_processor] to relabel metrics |
| [inclusions][prom_form_incl]                                    | Use [filter processor][filter_processor]                                                                  |
| [strict_inclusions][prom_form_strict_incl]                      | Use [filter processor][filter_processor]                                                                  |
| [exclusions][prom_form_excl]                                    | Use [filter processor][filter_processor]                                                                  |
| [strict_exclusions][prom_form_strict_excl]                      | Use [filter processor][filter_processor]                                                                  |

[filter_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.47.0/processor/filterprocessor#filter-processor
[fluent_plugin_prometheus_format]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format
[groupbyattrs_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.47.0/processor/groupbyattrsprocessor#group-by-attributes-processor
[prom_form_excl]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#exclusions-hash-optional
[prom_form_incl]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#inclusions-hash-optional
[prom_form_relabel]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#relabel-hash-optional
[prom_form_strict_excl]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#strict_exclusions-bool-optional
[prom_form_strict_incl]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#strict_inclusions-bool-optional
[resource_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.47.0/processor/resourceprocessor#resource-processor

### fluent-plugin-kubernetes-sumologic

| [Fluentd configuration option][fluent_plugin_k8s_sumologic] | Opentelemetry Collector                                                                                                                                      |
|-------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `source_category`                                           | [processors.source.source_category][source_processor] along with [exporters.sumologic.sourceCategory: '%{_sourceCategory}'][sumologic_exporter]              |
| `source_category_replace_dash`                              | [processors.source.source_category_replace_dash][source_processor] along with [exporters.sumologic.sourceCategory: '%{_sourceCategory}'][sumologic_exporter] |
| `source_category_prefix`                                    | [processors.source.source_category_prefix][source_processor] along with [exporters.sumologic.sourceCategory: '%{_sourceCategory}][sumologic_exporter]        |
| `source_name`                                               | [processors.source.source_name][source_processor] along with [exporters.sumologic.sourceName: '%{_sourceName}'][sumologic_exporter]                          |
| `log_format`                                                | N/A                                                                                                                                                          |
| `source_host`                                               | [processors.source.source_host][source_processor] along with [exporters.sumologic.sourceHost: '%{_sourceHost}'][sumologic_exporter]                          |
| `exclude_container_regex`                                   | [processors.source.exclude][source_filtering]                                                                                                                |
| `exclude_facility_regex`                                    | [processors.source.exclude][source_filtering]                                                                                                                |
| `exclude_host_regex`                                        | [processors.source.exclude][source_filtering]                                                                                                                |
| `exclude_namespace_regex`                                   | [processors.source.exclude][source_filtering]                                                                                                                |
| `exclude_pod_regex`                                         | [processors.source.exclude][source_filtering]                                                                                                                |
| `exclude_priority_regex`                                    | [processors.source.exclude][source_filtering]                                                                                                                |
| `exclude_unit_regex`                                        | [processors.source.exclude][source_filtering]                                                                                                                |
| `per_container_annotations_enabled`                         | [processors.source.container_annotations.enabled][source_containers]                                                                                         |
| `per_container_annotation_prefixes`                         | [processors.source.container_annotations.prefixes][source_containers]                                                                                        |

Additional behavior:

| Description                                                                                                                                             | Opentelemetry Collector                                                                                                       |
|---------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| [Allow to use sanitized pod name in source templates](#sanitized-pod-name)                                                                              | [processors.source.pod_name_key][source_keys]                                                                                 |
| [Using _sumo_metadata to propagate configuration to output plugin][sumo_metadata]                                                                       | Use `_sourceName`, `_sourceCategory` and `_sourceHost` attributes in [source templates in exporter][otelcol_source_templates] |
| [Setting host to `record["_HOSTNAME"]` if `record['_SYSTEMD_UNIT']` exists][fluent_syslog]                                                              | [`processors.source.source_host: "%{_HOSTNAME}"`][source_processor]                                                           |
| [Using `namespace`, `pod`, `pod_name`, `pod_id`, `container`, `source_host`, `labels`, `namespace_labels` in source templates][fluent_source_templates] | [Support all resource attributes plus matching `pod_name_key`][source_processor_source_templates]                             |
| [Setting `undefined` for non-existing field in source templates][fluent_undefined]                                                                      | [Supported by source processor, not documented][otelcol_undefined]                                                            |
| [Filtering out records with `annotations["sumologic.com/exclude"]` set to `true`][fluent_annotations]                                                   | [Supported by source processor][otelcol_annotations]                                                                          |
| [Filtering in records with `annotations["sumologic.com/include"]` set to `true`][fluent_annotations]                                                    | [Supported by source processor][otelcol_annotations]                                                                          |
| [Ignoring `exclude` configuration if `annotations["sumologic.com/include"]` is set to `true`][otelcol_annotations]                                      | [Supported by source processor][otelcol_annotations]                                                                          |
| [Setting `log_format` to `annotations["sumologic.com/format"]`][fluent_format]                                                                          | `log_format` is configured statically in [sumologic exporter][sumologic_exporter]                                             |
| [Setting sourceHost to `annotations["sumologic.com/sourceHost"]`][fluent_source_host]                                                                   | [Not supported by source processor][otelcol_annotations]                                                                      |
| [Setting sourceName to `annotations["sumologic.com/sourceName"]`][fluent_source_name]                                                                   | [Not supported by source processor][otelcol_annotations]                                                                      |
| [Support for per container sourceCategory][fluent_container_source_category] (precedence over annotations described below)                              | [Supported by source processor][otelcol_annotations]                                                                          |
| [Setting sourceCategory as `sourceCategoryPrefix` + `sourceCategory` and replacing `-` with `sourceCategoryReplaceDash`][fluent_source_category]        | [Supported by source processor][otelcol_annotations]                                                                          |
| [overwrite `sourceCategory` by `annotations["sumologic.com/sourceCategory"]`][fluent_source_category]                                                   | [Supported by source processor][otelcol_annotations]                                                                          |
| [overwrite `sourceCategoryPrefix` by `annotations["sumologic.com/sourceCategoryPrefix"]`][fluent_source_category]                                       | [Supported by source processor][otelcol_annotations]                                                                          |
| [overwrite `sourceCategoryReplaceDash` by `annotations["sumologic.com/sourceCategoryReplaceDash"]`][fluent_source_category]                             | [Supported by source processor][otelcol_annotations]                                                                          |

#### sanitized pod name

Sanitized pod name is name portion of the pod. Please consider following examples:

- for a [daemonset][kube_daemonset] pod named `dset-otelcol-sumo-xa314` it's going to be `dset-otelcol-sumo`
- for a [deployment][kube_deployment] pod named `dep-otelcol-sumo-75675f5861-qasd2` it's going to be `dep-otelcol-sumo`
- for a [statefulset][kube_statefulset] pod named `st-otelcol-sumo-0` it's going to be `st-otelcol-sumo`

[fluent_annotations]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic#pod-annotations
[fluent_container_source_category]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/blob/5a020be965d59b69b6456b1ad1f67e372bc55c72/fluent-plugin-kubernetes-sumologic/lib/fluent/plugin/filter_kubernetes_sumologic.rb#L274-L288
[fluent_format]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/blob/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic/lib/fluent/plugin/filter_kubernetes_sumologic.rb#L192
[fluent_plugin_k8s_sumologic]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic#configuration
[fluent_source_category]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/blob/5a020be965d59b69b6456b1ad1f67e372bc55c72/fluent-plugin-kubernetes-sumologic/lib/fluent/plugin/filter_kubernetes_sumologic.rb#L248-L271
[fluent_source_host]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/blob/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic/lib/fluent/plugin/filter_kubernetes_sumologic.rb#L194-L196
[fluent_source_name]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/blob/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic/lib/fluent/plugin/filter_kubernetes_sumologic.rb#L197-L199
[fluent_source_templates]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/b2ff4a79d6db5695b36f277ead7371c152fe5520/deploy/docs/Best_Practices.md#templating-kubernetes-metadata
[fluent_syslog]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic/lib/fluent/plugin/filter_kubernetes_sumologic.rb#L130-L146
[fluent_undefined]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/blob/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic/lib/fluent/plugin/filter_kubernetes_sumologic.rb#L165
[kube_daemonset]: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
[kube_deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[kube_statefulset]: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset
[otelcol_annotations]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/sourceprocessor#pod-annotations
[otelcol_annotations_exclude]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/blob/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic/lib/fluent/plugin/filter_kubernetes_sumologic.rb#L171-L183
[otelcol_source_templates]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/exporter/sumologicexporter#source-templates
[otelcol_undefined]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.49.0-sumo-0/pkg/processor/sourceprocessor/attribute_filler.go#L113-L123
[source_containers]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/sourceprocessor#container-level-pod-annotations
[source_filtering]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/sourceprocessor#filtering-section
[source_keys]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/sourceprocessor#keys-section
[source_processor]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/sourceprocessor#config
[source_processor_source_templates]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/sourceprocessor#name-translation-and-template-keys
[sumo_metadata]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-kubernetes-sumologic#fluent-plugin-kubernetes-sumologic
[sumologic_exporter]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.49.0-sumo-0/pkg/exporter/sumologicexporter/README.md#sumo-logic-exporter

### fluent-plugin-kubernetes-metadata-filter

| [Fluentd configuration option][fluent_plugin_k8s_metadata] | [Opentelemetry Kubernetes Processor][k8sprocessor]                                                    |
|------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| `annotation_match`                                         | [processors.k8s_tagger.extract.annotations][k8sprocessor_field_extract]                               |
| `de_dot`                                                   | Behaves like `false`                                                                                  |
| `watch`                                                    | Behaves like `true`                                                                                   |
| `ca_file`                                                  | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `verify_ssl`                                               | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `client_cert`                                              | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `client_key`                                               | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `bearer_token_file`                                        | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `cache_size`                                               | N/A                                                                                                   |
| `cache_ttl`                                                | N/A                                                                                                   |

[fluent_plugin_k8s_metadata]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-kubernetes-metadata-filter#configuration
[k8sprocessor]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.49.0-sumo-0/pkg/processor/k8sprocessor
[k8sprocessor_field_extract]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/k8sprocessor#field-extract-config
[kubeconfig_auth_type]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.47.0/internal/k8sconfig/config.go#L53-L60

### fluent-plugin-enhance-k8s-metadata

| [Fluentd configuration option][fluent_plugin_enhance_k8s_metadata] | [Opentelemetry Kubernetes Processor][k8sprocessor]                                      |
|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `cache_size`                                                       | N/A                                                                                     |
| `cache_ttl`                                                        | N/A                                                                                     |
| `cache_refresh`                                                    | N/A                                                                                     |
| `cache_refresh_variation`                                          | N/A                                                                                     |
| `in_namespace_path`                                                | Uses [processors.k8s_tagger.pod_association: [{from: build_hostname}]][pod_association] |
| `in_pod_path`                                                      | Uses [processors.k8s_tagger.pod_association: [{from: build_hostname}]][pod_association] |
| `core_api_versions`                                                | Supports all                                                                            |
| `api_groups`                                                       | Supports all                                                                            |
| `data_type`                                                        | N/A                                                                                     |

[fluent_plugin_enhance_k8s_metadata]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-enhance-k8s-metadata#configuration
[pod_association]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.49.0-sumo-0/pkg/processor/k8sprocessor/doc.go#L17-L46

### fluent-plugin-events

There is no replacement for [fluent-plugin-events][fluent_plugin_events] in Opentelemetry Collector for now.

[fluent_plugin_events]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-events

## Configuration by pipelines

### Events

Events are not supported by `Opentelemetry Collector`

### Metrics

| Configuration path                                                      | Opentelemetry Collector                                                                                                                                     |
|-------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [sumologic.collectionMonitoring][readme]                                | [processors.filter][filter_processor]                                                                                                                       |
| [sumologic.metrics.enabled][readme]                                     | Respected                                                                                                                                                   |
| [sumologic.metrics.metadata.provider][readme]                           | Respected                                                                                                                                                   |
| [fluentd.metrics.statefulset.podAntiAffinity][readme]                   | [metadata.metrics.statefulset.podAntiAffinity][readme]                                                                                                      |
| [fluentd.metrics.statefulset.replicaCount][readme]                      | [metadata.metrics.statefulset.replicaCount][readme]                                                                                                         |
| [fluentd.metrics.statefulset.resources][readme]                         | [metadata.metrics.statefulset.resources][readme]                                                                                                            |
| [fluentd.metrics.statefulset.priorityClassName][readme]                 | [metadata.metrics.statefulset.priorityClassName][readme]                                                                                                    |
| [fluentd.metrics.autoscaling.enabled][readme]                           | [metadata.metrics.autoscaling.enabled][readme]                                                                                                              |
| [fluentd.metrics.autoscaling.minReplicas][readme]                       | [metadata.metrics.autoscaling.minReplicas][readme]                                                                                                          |
| [fluentd.metrics.autoscaling.maxReplicas][readme]                       | [metadata.metrics.autoscaling.maxReplicas][readme]                                                                                                          |
| [fluentd.metrics.autoscaling.targetCPUUtilizationPercentage][readme]    | [metadata.metrics.autoscaling.targetCPUUtilizationPercentage][readme]                                                                                       |
| [fluentd.metrics.autoscaling.targetMemoryUtilizationPercentage][readme] | [metadata.metrics.autoscaling.targetMemoryUtilizationPercentage][readme]                                                                                    |
| [fluentd.metrics.podDisruptionBudget][readme]                           | [metadata.metrics.podDisruptionBudget][readme]                                                                                                              |
| [fluentd.metrics.enabled][readme]                                       | [metadata.metrics.enabled][readme]                                                                                                                          |
| [sumologic.collector.sources.metrics][readme]                           | `default` source is used for all metrics ingestion                                                                                                          |
| [fluentd.metrics.extraEnvVars][readme]                                  | [metadata.metrics.statefulset.extraEnvVars][readme]                                                                                                         |
| [fluentd.metrics.extraVolumes][readme]                                  | [metadata.metrics.statefulset.extraVolumes][readme]                                                                                                         |
| [fluentd.metrics.extraVolumeMounts][readme]                             | [metadata.metrics.statefulset.extraVolumeMounts][readme]                                                                                                    |
| [fluentd.persistence.enabled][readme]                                   | [metadata.persistence.enabled][readme]                                                                                                                      |
| [fluentd.persistence.storageClass][readme]                              | [metadata.persistence.storageClass][readme]                                                                                                                 |
| [fluentd.persistence.accessMode][readme]                                | [metadata.persistence.accessMode][readme]                                                                                                                   |
| [fluentd.persistence.size][readme]                                      | [metadata.persistence.size][readme]                                                                                                                         |
| [fluentd.image.repository][readme]                                      | [metadata.image.repository][readme]                                                                                                                         |
| [fluentd.image.tag][readme]                                             | [metadata.image.tag][readme]                                                                                                                                |
| [fluentd.image.pullPolicy][readme]                                      | [metadata.image.pullPolicy][readme]                                                                                                                         |
| [fluentd.podSecurityPolicy.create][readme]                              | Not supported                                                                                                                                               |
| [fluentd.logLevel][readme]                                              | [metadata.metrics.logLevel][readme]                                                                                                                         |
| [fluentd.logLevelFilter][readme]                                        | Not supported. Own logs are being ingested                                                                                                                  |
| [fluentd.verifySsl][readme]                                             | [metadata.metrics.config.exporters.sumologic.tls.insecure_skip_verify](#sumologic-output-plugin)                                                            |
| [fluentd.proxyUri][readme]                                              | [metadata.metrics.statefulset.extraEnvVars](#sumologic-output-plugin)                                                                                       |
| [fluentd.compression.enabled][readme]                                   | [metadata.metrics.config.exporters.sumologic.compress_encoding](#sumologic-output-plugin)                                                                   |
| [fluentd.compression.encoding][readme]                                  | [metadata.metrics.config.exporters.sumologic.compress_encoding](#sumologic-output-plugin)                                                                   |
| [fluentd.securityContext.fsGroup][readme]                               | [metadata.securityContext.fsGroup][readme]                                                                                                                  |
| [fluentd.buffer][readme]                                                | [Persistent Queue][persistent_queue] with [File Storage extension][file_storage_extension] is in use, configuration under [metadata.metrics.config][readme] |
| [otelcol.metrics.enabled][readme]                                       | Respected                                                                                                                                                   |
| [fluentd.monitoring.input][readme]                                      | [otelcol.metrics.enabled][readme]                                                                                                                           |
| [fluentd.monitoring.output][readme]                                     | [otelcol.metrics.enabled][readme]                                                                                                                           |
| [fluentd.metadata.cacheSize][readme]                                    | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                        |
| [fluentd.metadata.cacheTtl][readme]                                     | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                        |
| [fluentd.metadata.cacheRefresh][readme]                                 | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                        |
| [fluentd.metadata.cacheRefreshVariation][readme]                        | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                        |
| [fluentd.metadata.pluginLogLevel][readme]                               | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                        |
| [fluentd.metadata.coreApiVersions][readme]                              | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                        |
| [fluentd.metadata.apiGroups][readme]                                    | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                        |
| [sumologic.collectorName][readme]                                       | `metadata.metrics.config.processors.source.collector`                                                                                                       |
| [sumologic.clusterName][readme]                                         | `metadata.metrics.config.processors.source.collector`                                                                                                       |

[filter_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.47.0/processor/filterprocessor#filter-processor
[readme]: ../helm/sumologic/README.md
[persistent_queue]: https://github.com/open-telemetry/opentelemetry-collector/tree/release/v0.37.x/exporter/exporterhelper#persistent-queue
[file_storage_extension]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/release/v0.37.x/extension/storage/filestorage

### Logs

| Configuration path                                                   | Opentelemetry Collector                                                                                                                                                                                         |
|----------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [sumologic.collectionMonitoring][readme]                             | Respected                                                                                                                                                                                                       |
| [sumologic.logs.metadata.provider][readme]                           | Respected                                                                                                                                                                                                       |
| [sumologic.collector.sources.logs][readme]                           | Respected                                                                                                                                                                                                       |
| [fluentd.persistence.enabled][readme]                                | [metadata.persistence.enabled][readme]                                                                                                                                                                          |
| [fluentd.persistence.storageClass][readme]                           | [metadata.persistence.storageClass][readme]                                                                                                                                                                     |
| [fluentd.persistence.accessMode][readme]                             | [metadata.persistence.accessMode][readme]                                                                                                                                                                       |
| [fluentd.persistence.size][readme]                                   | [metadata.persistence.size][readme]                                                                                                                                                                             |
| [fluentd.image.repository][readme]                                   | [metadata.image.repository][readme]                                                                                                                                                                             |
| [fluentd.image.tag][readme]                                          | [metadata.image.tag][readme]                                                                                                                                                                                    |
| [fluentd.image.pullPolicy][readme]                                   | [metadata.image.pullPolicy][readme]                                                                                                                                                                             |
| [fluentd.podSecurityPolicy.create][readme]                           | Not supported                                                                                                                                                                                                   |
| [fluentd.logLevel][readme]                                           | [metadata.logs.logLevel][readme]                                                                                                                                                                                |
| [fluentd.logLevelFilter][readme]                                     | Not supported. Own logs are being ingested                                                                                                                                                                      |
| [fluentd.verifySsl][readme]                                          | [metadata.logs.config.exporters.sumologic/containers.tls.insecure_skip_verify](#sumologic-output-plugin), [metadata.logs.config.exporters.sumologic/systemd.tls.insecure_skip_verify](#sumologic-output-plugin) |
| [fluentd.proxyUri][readme]                                           | [metadata.metrics.statefulset.extraEnvVars](#sumologic-output-plugin)                                                                                                                                           |
| [fluentd.compression.enabled][readme]                                | [metadata.logs.config.exporters.sumologic/containers.compress_encoding](#sumologic-output-plugin), [metadata.logs.config.exporters.sumologic/systemd.compress_encoding](#sumologic-output-plugin)               |
| [fluentd.compression.encoding][readme]                               | [metadata.logs.config.exporters.sumologic/containers.compress_encoding](#sumologic-output-plugin), [metadata.logs.config.exporters.sumologic/systemd.compress_encoding](#sumologic-output-plugin)               |
| [fluentd.securityContext.fsGroup][readme]                            | [metadata.securityContext.fsGroup][readme]                                                                                                                                                                      |
| [fluentd.buffer][readme]                                             | [Persistent Queue][persistent_queue] with [File Storage extension][file_storage_extension] is in use, configuration under [metadata.logs.config][readme]                                                        |
| [otelcol.metrics.enabled][readme]                                    | Respected                                                                                                                                                                                                       |
| [fluentd.monitoring.input][readme]                                   | [otelcol.metrics.enabled][readme]                                                                                                                                                                               |
| [fluentd.monitoring.output][readme]                                  | [otelcol.metrics.enabled][readme]                                                                                                                                                                               |
| [fluentd.metadata.annotation_match][readme]                          | [metadata.logs.config.processors.k8s_tagger.extract.annotations](#fluent-plugin-kubernetes-metadata-filter)                                                                                                     |
| [fluentd.metadata.cacheSize][readme]                                 | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                                                                            |
| [fluentd.metadata.cacheTtl][readme]                                  | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                                                                            |
| [fluentd.metadata.cacheRefresh][readme]                              | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                                                                            |
| [fluentd.metadata.cacheRefreshVariation][readme]                     | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                                                                            |
| [fluentd.metadata.pluginLogLevel][readme]                            | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                                                                            |
| [fluentd.metadata.coreApiVersions][readme]                           | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                                                                            |
| [fluentd.metadata.apiGroups][readme]                                 | [Not supported](#fluent-plugin-enhance-k8s-metadata)                                                                                                                                                            |
| [fluentd.logs.enabled][readme]                                       | [metadata.logs.enabled][readme]                                                                                                                                                                                 |
| [fluentd.logs.statefulset.podAntiAffinity][readme]                   | [metadata.logs.statefulset.podAntiAffinity][readme]                                                                                                                                                             |
| [fluentd.logs.statefulset.replicaCount][readme]                      | [metadata.logs.statefulset.replicaCount][readme]                                                                                                                                                                |
| [fluentd.logs.statefulset.resources][readme]                         | [metadata.logs.statefulset.resources][readme]                                                                                                                                                                   |
| [fluentd.logs.statefulset.priorityClassName][readme]                 | [metadata.logs.statefulset.priorityClassName][readme]                                                                                                                                                           |
| [fluentd.logs.autoscaling.enabled][readme]                           | [metadata.logs.autoscaling.enabled][readme]                                                                                                                                                                     |
| [fluentd.logs.autoscaling.minReplicas][readme]                       | [metadata.logs.autoscaling.minReplicas][readme]                                                                                                                                                                 |
| [fluentd.logs.autoscaling.maxReplicas][readme]                       | [metadata.logs.autoscaling.maxReplicas][readme]                                                                                                                                                                 |
| [fluentd.logs.autoscaling.targetCPUUtilizationPercentage][readme]    | [metadata.logs.autoscaling.targetCPUUtilizationPercentage][readme]                                                                                                                                              |
| [fluentd.logs.autoscaling.targetMemoryUtilizationPercentage][readme] | [metadata.logs.autoscaling.targetMemoryUtilizationPercentage][readme]                                                                                                                                           |
| [fluentd.logs.podDisruptionBudget][readme]                           | [metadata.logs.podDisruptionBudget][readme]                                                                                                                                                                     |
| [fluentd.logs.rawConfig][readme]                                     | [metadata.logs.config][readme]; mind that configuration is going to be merged unless you use `null`                                                                                                             |
| [fluentd.logs.input.forwardExtraConf][readme]                        | [metadata.logs.config][readme]; mind that configuration is going to be merged unless you use `null`                                                                                                             |
| [fluentd.logs.output.logFormat][readme]                              | [metadata.logs.config.exporters.sumologic/containers.log_format](#sumologic-output-plugin), [metadata.logs.config.exporters.sumologic/systemd.log_format](#sumologic-output-plugin)                             |
| [fluentd.logs.output.addTimestamp][readme]                           | [metadata.logs.config.exporters.sumologic/containers.json_logs.add_timestamp](#sumologic-output-plugin), [metadata.logs.config.exporters.sumologic/systemd.json_logs.add_timestamp](#sumologic-output-plugin)   |
| [fluentd.logs.output.timestampKey][readme]                           | [metadata.logs.config.exporters.sumologic/containers.json_logs.timestamp_key](#sumologic-output-plugin), [metadata.logs.config.exporters.sumologic/systemd.json_logs.timestamp_key](#sumologic-output-plugin)   |
| [fluentd.logs.output.pluginLogLevel][readme]                         | Not supported                                                                                                                                                                                                   |
| [fluentd.logs.output.extraConf][readme]                              | [metadata.logs.config.exporters.sumologic/containers](#sumologic-output-plugin), [metadata.logs.config.exporters.sumologic/systemd](#sumologic-output-plugin)                                                   |
| [fluentd.logs.extraLogs][readme]                                     | [metadata.logs.config][readme]; mind that configuration is going to be merged unless you use `null`                                                                                                             |
| [fluentd.logs.containers.overrideRawConfig][readme]                  | [metadata.logs.config][readme]; mind that configuration is going to be merged unless you use `null`                                                                                                             |
| [fluentd.logs.containers.outputConf][readme]                         | [metadata.logs.config][readme]; mind that configuration is going to be merged unless you use `null`                                                                                                             |
| [fluentd.logs.containers.overrideOutputConf][readme]                 | [metadata.logs.config][readme]; mind that configuration is going to be merged unless you use `null`                                                                                                             |
| [fluentd.logs.containers.sourceName][readme]                         | [metadata.logs.config.processors.source/containers.source_name](#fluent-plugin-kubernetes-sumologic) with attributes using semantic OTC convention                                                              |
| [fluentd.logs.containers.sourceCategory][readme]                     | [metadata.logs.config.processors.source/containers.source_category](#fluent-plugin-kubernetes-sumologic) with attributes using semantic OTC convention                                                          |
| [fluentd.logs.containers.sourceCategoryPrefix][readme]               | [metadata.logs.config.processors.source/containers.source_category_prefix](#fluent-plugin-kubernetes-sumologic)                                                                                                 |
| [fluentd.logs.containers.sourceCategoryReplaceDash][readme]          | [metadata.logs.config.processors.source/containers.source_category_replace_dash](#fluent-plugin-kubernetes-sumologic)                                                                                           |
| [fluentd.logs.containers.excludeNamespaceRegex][readme]              | [metadata.logs.config.processors.source/containers.exclude.'k8s.namespace.name'](#fluent-plugin-kubernetes-sumologic)                                                                                           |
| [fluentd.logs.containers.excludeHostRegex][readme]                   | [metadata.logs.config.processors.source/containers.exclude.'k8s.pod.hostname'](#fluent-plugin-kubernetes-sumologic)                                                                                             |
| [fluentd.logs.containers.excludeContainerRegex][readme]              | [metadata.logs.config.processors.source/containers.exclude.'k8s.container.name'](#fluent-plugin-kubernetes-sumologic)                                                                                           |
| [fluentd.logs.containers.excludePodRegex][readme]                    | [metadata.logs.config.processors.source/containers.exclude.'k8s.pod.name'](#fluent-plugin-kubernetes-sumologic)                                                                                                 |
| [sumologic.collectorName][readme]                                    | `metadata.logs.config.processors.source/containers.collector`, `metadata.logs.config.processors.source/systemd.collector`, `metadata.logs.config.processors.source/kubelet.collector`                           |
| [sumologic.clusterName][readme]                                      | `metadata.logs.config.processors.source/containers.collector`, `metadata.logs.config.processors.source/systemd.collector`, `metadata.logs.config.processors.source/kubelet.collector`                           |
| [fluentd.logs.containers.perContainerAnnotationsEnabled][readme]     | [metadata.logs.config.processors.source/containers.container_annotations.enabled][source_containers]                                                                                                            |
| [fluentd.logs.containers.perContainerAnnotationPrefixes][readme]     | [metadata.logs.config.processors.source/containers.container_annotations.prefixes][source_containers]                                                                                                           |
| [fluentd.logs.containers.k8sMetadataFilter.watch][readme]            | [metadata.logs.config.processors.k8s_tagger.auth_type](#fluent-plugin-kubernetes-metadata-filter)                                                                                                               |
| [fluentd.logs.containers.k8sMetadataFilter.caFile][readme]           | [metadata.logs.config.processors.k8s_tagger.auth_type](#fluent-plugin-kubernetes-metadata-filter)                                                                                                               |
| [fluentd.logs.containers.k8sMetadataFilter.verifySsl][readme]        | [metadata.logs.config.processors.k8s_tagger.auth_type](#fluent-plugin-kubernetes-metadata-filter)                                                                                                               |
| [fluentd.logs.containers.k8sMetadataFilter.clientCert][readme]       | [metadata.logs.config.processors.k8s_tagger.auth_type](#fluent-plugin-kubernetes-metadata-filter)                                                                                                               |
| [fluentd.logs.containers.k8sMetadataFilter.clientKey][readme]        | [metadata.logs.config.processors.k8s_tagger.auth_type](#fluent-plugin-kubernetes-metadata-filter)                                                                                                               |
| [fluentd.logs.containers.k8sMetadataFilter.bearerTokenFile][readme]  | [metadata.logs.config.processors.k8s_tagger.auth_type](#fluent-plugin-kubernetes-metadata-filter)                                                                                                               |
| [fluentd.logs.containers.extraFilterPluginConf][readme]              | [metadata.logs.config][readme]; mind that configuration is going to be merged unless you use `null`                                                                                                             |
| [fluentd.logs.containers.extraOutputPluginConf][readme]              | [metadata.logs.config][readme]; mind that configuration is going to be merged unless you use `null`                                                                                                             |

[filter_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.47.0/processor/filterprocessor#filter-processor
[readme]: ../helm/sumologic/README.md
[source_containers]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.49.0-sumo-0/pkg/processor/sourceprocessor#container-level-pod-annotations
[persistent_queue]: https://github.com/open-telemetry/opentelemetry-collector/tree/release/v0.37.x/exporter/exporterhelper#persistent-queue
[file_storage_extension]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/release/v0.37.x/extension/storage/filestorage

### Other

| Configuration path                | Opentelemetry Collector |
|-----------------------------------|-------------------------|
| [otelcol.logLevelFilter][readme]  | Not respected           |
| [otelcol.metrics.enabled][readme] | Respected               |
