# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

- docs: FluentD buffer size configuration [#2232][#2232]

[#2232]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2232
[Unreleased]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.6.0...main

## [v2.7.0][v2.7.0]

### Released 2022-04-11

### Added

- feat: add pprof extension for otelcol [#2173][#2173]
- feat(tracing): traces load balancing gateway [#2137][#2137]
- feat: selectively disable cache for metadata enrichment calls [#2190][#2190]
- feat(otelcol): introduce default initialDelaySeconds [#2200][#2200]
- feat(otelcol): add startupProbe config option [#2201][#2201]
- feat: add topologySpreadContraints config option to logs and metrics metadata providers [#2211][#2211]

### Changed

- feat(tracing): change otlp http receiver default port to 4318 [#2170][#2170]
- chore(deps): bump prometheus node exporter tag to 2.3.1 [#2177][#2177]
- chore: upgrade Fluentd to 1.14.6-sumo-1 [#2230][#2230]
- chore: upgrade Falco Helm Chart to 1.17.4 [#2197][#2197]
- chore: bump sumo ot distro to 0.47.0-sumo-0 [#2220][#2220]
- feat: remove the experimental flag for otelcol as a metadata provider [#2221](#2221)

### Fixed

- fix(helm): always create default metrics source if traces are enabled [#2182][#2182]

[#2137]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2137
[#2170]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2170
[#2177]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2177
[#2173]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2173
[#2182]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2182
[#2190]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2190
[#2197]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2197
[#2200]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2200
[#2201]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2201
[#2211]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2211
[#2220]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2220
[#2221]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2221
[#2230]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2230
[v2.7.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.7.0

## [v2.6.0][v2.6.0]

### Released 2022-03-03

### Added

- feat: add otelcol's liveness and readiness probes configuration [#2105][#2105]
- docs: add fluentd buffers vs DPM calculations info for metrics [#2128][#2128]
- feat(otelcol/metrics): adjust metric otelcol configuration [#2134][#2134]
- feat: added remote write configs for couchbase [#2113][#2113]
- feat: added remote write configs for squidproxy [#2143][#2143]

### Changed

- fix: increase OTC liveness timeout and period [#2165][#2165]
- chore: bump sumo ot distro to 0.0.50-beta.0 [#2127][#2127]
- feat(metrics): drop container label for non-container kube state metrics [#2144][#2144]
- feat(fluent-bit): drop all capabilities for container [#2151][#2151]
- feat: allow to collect logs from /var/log/pods and add instruction how to do it [#2153][#2153] [#2156][#2156]
- feat(otellogs): support tolerations, nodeSelector and affinity for daemonset [#2158][#2158]
- feat(otellogs): add multipart merge configuration for docker and cri [#2162][#2162]
- chore(otellogs): increase send_batch_size to 10240 [#2161][#2161]
- chore(fluent-bit): update to 0.14.1 [#2155][#2155]

### Fixed

[#2105]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2105
[#2113]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2113
[#2127]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2127
[#2128]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2128
[#2134]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2134
[#2143]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2143
[#2144]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2144
[#2151]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2151
[#2153]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2153
[#2155]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2155
[#2156]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2156
[#2158]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2158
[#2161]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2161
[#2162]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2162
[#2165]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2165
[v2.6.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.6.0

## [v2.5.2]

### Released 2022-02-17

### Changed

- chore: change Fluent Bit image to `public.ecr.aws/sumologic/fluent-bit:1.6.10-sumo-1`,
  it is Fluent Bit 1.6.10 with updated dependencies,
  image repository: https://github.com/SumoLogic/fluent-bit-docker-image [#2131][#2131]

### Fixed

- fix: make metadata StatefulSets scale above 0.5 average CPU usage [#2114]
- fix(metrics): add missing telegraf (otelcol) endpoints [#2100]

[#2114]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2114
[#2100]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2100
[#2131]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2131
[v2.5.2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.5.2

## [v2.5.1]

### Released 2022-02-07

### Fixed

- fix: invalid checksum source for remote write proxy deployment [#2091][#2091]

[#2091]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2091
[v2.5.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.5.1

## [v2.5.0]

### Released 2022-02-07

### Added

- feat: add proxy for Prometheus remote write [#2065][#2065]
- feat: add CRI support to experimental otelcol log collector[#2017][#2017]
- docs(readme): add support for AKS 1.22 [#2075][#2075]
- docs(readme): add support for KOPS 1.22 [#2080][#2080]
- feat: add `fluentd.apiServerUrl` property [#2077][#2077]
- feat(otelcol/metrics): do not add host to metrics [#2085][#2085]

### Changed

- chore: upgrade Fluentd to 1.14.4-sumo-1 [#2057][#2057]
- chore: update the Telegraf image to 1.21.2 [#2036][#2036]
- chore(deps): bump Sumo OT distro to 0.0.48-beta.0 [#2056][#2056]
- chore: update Tailing Sidecar to 0.3.2 [#2073][#2073]
- chore: bump setup image to 3.2.2 [#2083][#2083]

### Fixed

- fix: disable the metadata pipeline for OTC log collector by default [#2084][#2084]
- fix: fix scheduler metrics remote write and relabel regex [#2058][#2058]

[#2036]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2036
[#2056]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2056
[#2057]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2057
[#2058]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2058
[#2075]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2075
[#2080]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2080
[#2017]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2017
[#2077]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2077
[#2083]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2083
[#2084]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2084
[#2065]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2065
[#2085]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2085
[#2073]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2073
[v2.5.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.5.0

## [v2.4.1][v2_4_1]

### Released 2022-02-02

### Changed

- [Backport release-v2.4] chore: update Telegraf to 1.21.2 [#2052][#2052]
- [Backport release-v2.4] chore: bump sumologic terraform provider to v2.11.5 [#2066][#2066]
- chore: bump setup image to 3.2.1 [#2064][#2064]

[v2_4_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.4.1
[#2052]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2052
[#2066]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2066
[#2064]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2064

## [v2.4.0][v2_4_0]

### Released 2022-01-25

### Added

- feat: export scheduler_framework_extension_point_duration metrics [#2033][#2033]
- docs: claim official ARM support [#2024][#2024]
- feat: add batching to experimental otelcol log collector [#2018][#2018]
- feat: add experimental otelcol log collector [#1986][#1986]
- feat: add option to disable pod owners enrichment [#1959][#1959]

### Changed

- chore: update setup image to 3.2.0 [#2020][#2020]
- chore: update kubernetes-tools to 2.9.0 [#2013][#2013]
- chore: bump Thanos image to our build of v0.23.1 [#1973][#1973]
- Introduced option to add cache refresh delay for metadata enrichment calls [#1974][#1974]
- chore(deps): bump Sumo OT distro to 0.0.47-beta.0 [#2035][#2035]

### Fixed

- fix(helm): add job and cronjob to clusterrole's permission set [#1983][#1983]
- fix(helm): add metrics port to otelcol pods [#1992][#1992]

[v2_4_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.4.0
[#1986]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1986
[#1959]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1959
[#1974]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1974
[#1973]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1973
[#1983]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1983
[#1992]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1992
[#2013]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2013
[#2018]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2018
[#2020]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2020
[#2035]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2035
[#2024]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2024
[#2033]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2024

## [v2.3.2][v2_3_2]

### Released 2021-12-21

#### Fixed

- fix(helm): add job and cronjob to clusterrole's permission set [#1994][#1994]

[#1994]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1994

[v2_3_2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.3.2

## [v2.3.1][v2_3_1] - 2021-12-14

### Fixed

- Fix otelcol agent template [#1975][#1975]

[v2_3_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.3.1
[#1975]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1975

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
[v0.38.1-cfp-help]: https://help.sumologic.com/Traces/03Advanced_Configuration/What_if_I_don%27t_want_to_send_all_the_tracing_data_to_Sumo_Logic%3F
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
