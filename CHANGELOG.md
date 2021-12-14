# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.3.1][v2_3_1] - 2021-12-14

### Fixed

- Fix otelcol agent template [#1975][#1975]

<!-- markdown-link-check-disable -->
[v2_3_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.3.1
<!-- markdown-link-check-enable -->
[1975]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1975

## [v2.3.0][v2_3_0] - 2021-12-8

### Added

- feat(helm): add fluentd init containers [#1928][#1928]
- Add support for GKE 1.21 [#1907][#1907]
- feat: add affinity to fluentd events statefulset [#1895][#1895]
- feat(helm): add PodDisruptionBudget api version helm chart helpers [#1865][#1865] [#1943][#1943]
- feat: add option to disable `service` enrichment [#1936][#1936]

### Changed

- Update fluentd to 1.12.2-sumo-10 [#1927][#1927]
- Update dependencies for ARM support [#1919][#1919]
  - Update kube-state-metrics to 1.9.8
  - Update kubernetes-setup to 3.1.1
  - Update kuberenetes-tools to 2.6.0
  - Update telegraf-operator subchart to 1.3.3
- Bump Sumo OT distro to `0.0.42-beta.0` [#1921][#1921]
- chore(deps): bump falco subchart to 1.16.2 [#1917][#1917]
- Remove support for EKS 1.17, GKE 1.18 and 1.19 [#1906][#1906]
- fix: fix Fluentd to support Kubernetes 1.22 [#1892][#1892]
- Update OpenTelemetry Collector version to v0.38.1-sumo [#1893][#1893]

  - Move insecure parameter to separate configuration variable
  - Fix OTLP/HTTP metadata tagging
  - Update [Cascading Filter processor][v0.38.1-cfp] to a new version which adds new features such filtering
    by number of errors and switches to a new, [easier to use config format][v0.38.1-cfp-help]
  - Change the default number of traces for Cascading Filter to 200000

### Fixed

- Reduced the number of API server calls from the metrics metadata enrichment plugin by a significant amount [#1927][#1927]

[v2_3_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.3.0
[v0.38.1-cfp]: https://github.com/SumoLogic/opentelemetry-collector-contrib/tree/v0.38.1-sumo/processor/cascadingfilterprocessor#cascading-filter-processor
[v0.38.1-cfp-help]: https://help.sumologic.com/Traces/Getting_Started_with_Transaction_Tracing/What_if_I_don't_want_to_send_all_the_tracing_data_to_Sumo_Logic%3F
[#1907]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1907
[#1906]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1906
[#1895]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1895
[#1893]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1893
[#1892]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1892
[#1865]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1865
[#1921]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1921
[#1917]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1917
[#1919]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1919
[#1927]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1927
[#1928]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1928
[#1936]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1936
[#1943]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1943

## [v2.2.0][v2_2_0] - 2021-11-17

### Added

- Add support otelcol for metrics pipeline [#1702][#1702]
- Add otelcol as alternative logs metadata provider [#1697][#1697]

  Adds new `values.yaml` property `sumologic.logs.metadata.provider` and associated configuration properties
  to replace Fluentd with Sumo Logic Distro of OpenTelemetry Collector for logs metadata enrichment.

- otelcol: add systemd logs pipeline [#1767][#1767]

  - This change introduces logs metadata enrichment with Sumo Open Telemetry
    distro for systemd logs (when `sumologic.logs.metadata.provider` is set to
    `otelcol`)

    One notable change comparing the new behavior to `fluentd` metadata enrichment
    is that setting source name in `sourceprocessor` configuration is respected
    i.e.  whatever is set in
    `otelcol.metadata.logs.config.processors.source/systemd.source_name` will be
    set as source name for systemd logs.

    The old behavior is being retained i.e. extracting the source name from
    `fluent.tag` using `attributes/extract_systemd_source_name_from_fluent_tag`
    processor. For instance, for `fluent.tag=host.docker.service`, source name
    will be set to `docker`.

    In order to set the source name to something else please change
    `otelcol.metadata.logs.config.processors.source/systemd:.source_name`
    configuration value.
- feat(otelcol/logs/kubelet): add kubelet logs pipeline [#1772][#1772]
- Enable custom labels for events, metrics and logs services [#1550][#1550]
- Add remote write configs for Kafka Metrics [#1554][#1554]
- Add remote write configs for MySQL telegraf metrics [#1561][#1561]
- Add remote write configs for PostgreSQL metrics [#1577][#1577]
- Add remoteWrite section for Apache Telegraf metrics collection [#1598][#1598]
- Add regex for Nginx Plus metrics [#1620][#1620]
- Add Nginx Plus to Prometheus remote write [#1656][#1656]
- Add remote write configs for SQLserver Metrics [#1749][#1749]
- Add remote write configs for Haproxy Metrics [#1748][#1748]
- Add remote write configs for Cassandra Metrics [#1747][#1747]
- Add remote write configs for MongoDB Metrics [#1746][#1746]
- Add remote write configs for RabbitMQ Metrics [#1734][#1734]
- Add remote write configs for Tomcat Metrics [#1733][#1733]
- Add remote write configs for Varnish metrics [#1779][#1779]
- Add remote write for Memcached [#1780][#1780]
- Add remote write configs for ActiveMQ Metrics [#1833][#1833]

### Changed

- Update falco subchart to 1.11.1 [#1618][#1618]
- feat: ingest stacktraces from fluentd [#1585][#1585]
- feat: forward kube_hpa_status_condition metric [#1632][#1632]
- refactor(prometheus): unify application metrics urls [#1631][#1631]
- refactor(helm): add helper function to add quotes to annotation_match [#1655][#1655]

  quote function is not use as it automatically adds '\' before special characters

  Change default value of `fluentd.metadata.annotation_match` to `['sumologic\.com.*']`

- feat(deploy/otc): ensure backward compatibility for tpl change [#1721][#1721]
- fix(setup): hide custom-configmap if setup is disabled [#1804][#1804]
- fix: don't include fluentd.logs.containers.excludeNamespaceRegex in ns exclusion regex
  when collectionMonitoring is disabled [#1852][#1852]
- fix: use fluentd.excludeNamespaces helm template, also for tracing config [#1857][#1857]
- Limited k8s scrape [#1861][#1861]

[#1550]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1550
[#1554]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1554
[#1561]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1561
[#1577]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1577
[#1585]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1585
[#1598]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1598
[#1618]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1618
[#1620]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1620
[#1631]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1631
[#1632]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1632
[#1655]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1655
[#1656]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1656
[#1697]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1697
[#1702]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1702
[#1721]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1721
[#1733]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1733
[#1734]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1734
[#1746]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1746
[#1747]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1747
[#1748]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1748
[#1749]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1749
[#1767]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1767
[#1772]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1772
[#1779]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1779
[#1780]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1780
[#1804]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1804
[#1829]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1829
[#1833]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1833
[#1852]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1852
[#1857]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1857
[#1861]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1861
[v2_2_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.2.0

## [v2.1.7][v2_1_7] - 2021-11-15

### Changed

- feat: add remote write config for Elasticsearch metrics [#1819][#1819]
- fix(deps): upgrade Fluentd to 1.12.2-sumo-6 [#1868][#1868]
- feat: Add fullnameOverride chart parameter [#1871][#1871]

[v2_1_7]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.7
[#1819]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1819
[#1868]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1868
[#1871]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1871

## [v2.1.6][v2_1_6] - 2021-09-28

### Changed

- Fixing regex for Istio logs, splitting istio logs [#1781]
- docs: improve documentation for installation on OpenShift
- chore: bump telegraf operator subchart to 1.2.0 [#1723]
- feat(helm): add sumologic.serviceAccount.annotations so custom annotation cen be added [#1716]

[v2_1_6]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.6
[#1781]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1781
[#1723]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1723
[#1716]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1716

## [v2.1.5][v2_1_5] - 2021-07-21

### Changed

- fix(deps): Upgrade Fluentd from `v1.12.2-sumo-0` to `v1.12.2-sumo-2` [#1693][#1693]

[v2_1_5]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.5
[#1693]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1693
