# Comparison of functionality of Fluentd and Opentelemetry Collector

- [Sumologic supported Fluentd plugins](#sumologic-supported-fluentd-plugins)
  - [Sumologic Output Plugin][#sumologic-output-plugin]
  - [fluent-plugin-datapoint][#fluent-plugin-datapoint]
  - [fluent-plugin-protobuf][#fluent-plugin-protobuf]
  - [fluent-plugin-prometheus-format][#fluent-plugin-prometheus-format]
  - [fluent-plugin-kubernetes-sumologic][#fluent-plugin-kubernetes-sumologic]
  - [fluent-plugin-kubernetes-metadata-filter][#fluent-plugin-kubernetes-metadata-filter]
  - [fluent-plugin-enhance-k8s-metadata][#fluent-plugin-enhance-k8s-metadata]
  - [fluent-plugin-events][#fluent-plugin-events]

## Sumologic supported Fluentd plugins

### Sumologic Output Plugin

| [Fluentd configuration option][fluentd_output_plugin] | otelcol                                                                                                                    |
|-------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `data_type`                                           | Defined by pipeline type (`service.pipelines`). [See basic configuration documentation][otelcol_basic_confg]               |
| `endpoint`                                            | [exporters.sumologic.endpoint][otelcol_sumologic_config]                                                                   |
| `verify_ssl`                                          | [exporters.sumologic.tls.insecure_skip_verify][otelocl_tls_config]                                                         |
| `source_category`                                     | [processors.source.source_category][otelcol_source_config]. Placeholders format changed to `%{}`.                          |
| `source_name`                                         | [processors.source.source_name][otelcol_source_config]. Placeholders format changed to `%{}`.                              |
| `source_name_key`                                     | TBD                                                                                                                        |
| `source_host`                                         | [processors.source.source_host][otelcol_source_config]. Placeholders format changed to `%{}`.                              |
| `log_format`                                          | [exporters.sumologic.log_format][otelcol_sumologic_config] (`json_merge` and `fields` formats are not supported)           |
| `log_key`                                             | [exporters.sumologic.json_logs.log_key][otelcol_sumologic_config]                                                          |
| `open_timeout`                                        | [exporters.sumologic.timeout][otelcol_sumologic_config] (doesn't differentiate between `open` and `send`)                  |
| `send_timeout`                                        | [exporters.sumologic.timeout][otelcol_sumologic_config] (doesn't differentiate between `open` and `send`)                  |
| `add_timestamp`                                       | [exporters.sumologic.json_logs.add_timeout][otelcol_sumologic_config]                                                      |
| `timestamp_key`                                       | [exporters.sumologic.json_logs.timestamp_key][otelcol_sumologic_config]                                                    |
| `proxy_uri`                                           | [environment variables][otelcol_proxy]                                                                                     |
| `metric_data_format`                                  | [exporters.sumologic.metric_format][otelcol_sumologic_config]                                                              |
| `disable_cookies`                                     | Cookies are not used in Opentelemetry Collector                                                                            |
| `compress`                                            | [exporters.sumologic.compress_encoding][otelcol_sumologic_config] set to `""`                                              |
| `compress_encoding`                                   | [exporters.sumologic.compress_encoding][otelcol_sumologic_config]                                                          |
| `custom_fields`                                       | [Resource processor][resource_processor] combined with [exporters.sumologic.metadata_attributes][otelcol_sumologic_config] |
| `custom_dimensions`                                   | [Resource processor][resource_processor] combined with [exporters.sumologic.metadata_attributes][otelcol_sumologic_config] |

Additional behavior:

| description                                                                                                    | otelcol                                                                                                                                                  |
|----------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [record[_sumo_metadata][source_name]][source_name_precedence] taking precedence over `source_name`             | can be achieved by separate pipelines                                                                                                                    |
| [record[_sumo_metadata][source_host]][source_host_precedence] taking precedence over `source_host`             | can be achieved by separate pipelines                                                                                                                    |
| [record[_sumo_metadata][source_category]][source_category_precedence] taking precedence over `source_category` | can be achieved by separate pipelines                                                                                                                    |
| [record[_sumo_metadata][fields]][fields_base] being base for fields                                            | ca be achieved using [resource processor][resource_processor], separate pipelines and [exporter.sumologic.metadata_attributes][otelcol_sumologic_config] |

[fluentd_output_plugin]: https://github.com/sumologic/fluentd-output-sumologic/tree/1.7.2#configuration
[otelcol_basic_confg]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.0.27-beta.0/docs/Configuration.md#basic-configuration
[otelcol_sumologic_config]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.0.27-beta.0/pkg/exporter/sumologicexporter/README.md#sumo-logic-exporter
[otelocl_tls_config]: https://github.com/open-telemetry/opentelemetry-collector/blob/v0.36.0/config/configtls/README.md#tls--mtls-configuration
[otelcol_source_config]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.0.27-beta.0/pkg/processor/sourceprocessor#config
[otelcol_proxy]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.0.27-beta.0/docs/Configuration.md#proxy-support
[resource_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.36.0/processor/resourceprocessor#resource-processor
[source_name_precedence]: https://github.com/SumoLogic/fluentd-output-sumologic/blob/1.7.2/lib/fluent/plugin/out_sumologic.rb#L275-L276
[source_host_precedence]: https://github.com/SumoLogic/fluentd-output-sumologic/blob/1.7.2/lib/fluent/plugin/out_sumologic.rb#L281-L282
[source_category_precedence]: https://github.com/SumoLogic/fluentd-output-sumologic/blob/1.7.2/lib/fluent/plugin/out_sumologic.rb#L278-L279
[fields_base]: https://github.com/SumoLogic/fluentd-output-sumologic/blob/1.7.2/lib/fluent/plugin/out_sumologic.rb#L284-L285

### fluent-plugin-datapoint

In order to receive prometheus data and for them initial processing [telegrafreceiver][telegrafreceiver] is being used.
It should cover [fluent-plugin-datapoint][fluent_plugin_datapoint] functionality and more.

[telegrafreceiver]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.0.27-beta.0/pkg/receiver/telegrafreceiver
[fluent_plugin_datapoint]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-datapoint

### fluent-plugin-protobuf

In order to receive prometheus data and for them initial processing [telegrafreceiver][telegrafreceiver] is being used.
It should cover [fluent_plugin_protobuf][fluent_plugin_protobuf] functionality and more.

[telegrafreceiver]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.0.27-beta.0/pkg/receiver/telegrafreceiver
[fluent_plugin_protobuf]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-protobuf

### fluent-plugin-prometheus-format

| [Fluentd configuration option][fluent_plugin_prometheus_format] | otelcol                                                                                                   |
|-----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| [relabel][prom_form_relabel]                                    | Use [groupbyattrs][groupbyattrs_processor] and [resourceprocessor][resource_processor] to relabel metrics |
| [inclusions][prom_form_incl]                                    | Use [filter][filter_processor]                                                                            |
| [strict_inclusions][prom_form_strict_incl]                      | Use [filter][filter_processor]                                                                            |
| [exclusions][prom_form_excl]                                    | Use [filter][filter_processor]                                                                            |
| [strict_exclusions][prom_form_strict_excl]                      | Use [filter][filter_processor]                                                                            |

[fluent_plugin_prometheus_format]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format
[prom_form_relabel]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#relabel-hash-optional
[prom_form_incl]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#inclusions-hash-optional
[prom_form_strict_incl]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#strict_inclusions-bool-optional
[prom_form_excl]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#exclusions-hash-optional
[prom_form_strict_excl]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-prometheus-format#strict_exclusions-bool-optional
[groupbyattrs_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.36.0/processor/groupbyattrsprocessor#group-by-attributes-processor
[resource_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.36.0/processor/resourceprocessor#resource-processor
[filter_processor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.36.0/processor/filterprocessor#filter-processor

### fluent-plugin-kubernetes-sumologic

| [Fluentd configuration option][fluent_plugin_k8s_sumologic] | otelcol                                                                                                                                                      |
|-------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `source_category`                                           | [processors.source.source_category][source_processor] along with [exporters.sumologic.sourceCategory: '%{_sourceCategory}'][sumologic_exporter]              |
| `source_category_replace_dash`                              | [processors.source.source_category_replace_dash][source_processor] along with [exporters.sumologic.sourceCategory: '%{_sourceCategory}'][sumologic_exporter] |
| `source_category_prefix`                                    | [processors.source.source_category_prefix][source_processor] along with [exporters.sumologic.sourceCategory: '%{_sourceCategory}][sumologic_exporter]        |
| `source_name`                                               | [processors.source.source_name][source_processor] along with [exporters.sumologic.sourceName: '%{_sourceName}'][sumologic_exporter]                          |
| `log_format`                                                | N/A                                                                                                                                                          |
| `source_host`                                               | [processors.source.source_host][source_processor] along with [exporters.sumologic.sourceHost: '%{_sourceHost}'][sumologic_exporter]                          |
| `exclude_container_regex`                                   | [processors.source.exclude][source_filtering]                                                                                                                  |
| `exclude_facility_regex`                                    | [processors.source.exclude][source_filtering]                                                                                                                  |
| `exclude_host_regex`                                        | [processors.source.exclude][source_filtering]                                                                                                                  |
| `exclude_namespace_regex`                                   | [processors.source.exclude][source_filtering]                                                                                                                  |
| `exclude_pod_regex`                                         | [processors.source.exclude][source_filtering]                                                                                                                  |
| `exclude_priority_regex`                                    | [processors.source.exclude][source_filtering]                                                                                                                  |
| `exclude_unit_regex`                                        | [processors.source.exclude][source_filtering]                                                                                                                  |
| `per_container_annotations_enabled`                         | TBD                                                                                                                                                          |
| `per_container_annotation_prefixes`                         | TBD                                                                                                                                                          |

[fluent_plugin_k8s_sumologic]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/main/fluent-plugin-kubernetes-sumologic#configuration
[source_processor]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.0.27-beta.0/pkg/processor/sourceprocessor#config
[sumologic_exporter]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.0.27-beta.0/pkg/exporter/sumologicexporter/README.md#sumo-logic-exporter
[source_filtering]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.0.27-beta.0/pkg/processor/sourceprocessor#filtering-section

### fluent-plugin-kubernetes-metadata-filter

| [Fluentd configuration option][fluent_plugin_k8s_metadata] | [Opentelemetry Kubernetes Processor][k8sprocessor]                                                    |
|------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| `annotation_match`                                         | [processors.k8s_tagger.extract.annotations][k8sprocessor_field_extract]                               |
| `de_dot`                                                   | behaves like `false`                                                                                  |
| `watch`                                                    | behaves like `true`                                                                                   |
| `ca_file`                                                  | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `verify_ssl`                                               | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `client_cert`                                              | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `client_key`                                               | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `bearer_token_file`                                        | No direct translation. Please use [processors.k8s_tagger.auth_type: kubeconfig][kubeconfig_auth_type] |
| `cache_size`                                               | N/A                                                                                                   |
| `cache_ttl`                                                | N/A                                                                                                   |

[fluent_plugin_k8s_metadata]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-kubernetes-metadata-filter#configuration
[k8sprocessor]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.0.27-beta.0/pkg/processor/k8sprocessor
[k8sprocessor_field_extract]: https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.0.27-beta.0/pkg/processor/k8sprocessor#field-extract-config
[kubeconfig_auth_type]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v0.36.0/internal/k8sconfig/config.go#L53-L60

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
[pod_association]: https://github.com/SumoLogic/sumologic-otel-collector/blob/v0.0.27-beta.0/pkg/processor/k8sprocessor/doc.go#L17-L46

### fluent-plugin-events

There is no replacement for [fluent-plugin-events][fluent_plugin_events] in Opentelemetry Collector for now.

[fluent_plugin_events]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/tree/v1.12.2-sumo-4/fluent-plugin-events
