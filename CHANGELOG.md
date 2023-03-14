# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- chore: upgrade Fluentd to v1.15.3-sumo-0 [#2747]
  - This also upgrades Ruby from `v2.7` to `v3.1` and some other dependencies.
    See [v1.15.3-sumo-0] for more.
- chore: remove support for AKS 1.22 [#2757]

### Fixed

- fix(logs): make `excludeHostRegex` consistent between Otelcol and Fluentd [#2772]
  - The `fluentd.logs.container.excludeHostRegex` should filter on the Kubernetes node name
    when the metadata provider is Otelcol, to be consistent with Fluentd.

[#2747]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2747
[v1.15.3-sumo-0]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/releases/tag/v1.15.3-sumo-0
[#2757]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2757
[#2772]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2772
[Unreleased]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.19.1...release-v2

## [v2.19.1]

### Released 2022-12-29

### Changed

- chore: upgrade Fluent Bit to v1.6.10-sumo-3 [#2730]

### Fixed

- The repository for the metrics-server dependency was updated [#2730]

[#2730]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2730
[v2.19.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.19.0...v2.19.1

## [v2.19.0]

### Released 2022-11-24

If you use custom configuration for Telegraf Operator Helm Chart with cert-manager enabled (`telegraf-operator.certManager.enable=true`) please note that
in this release Telegraf Operator Helm Chart is changed to 1.3.10 which uses the cert-manager apiVersion `cert-manager.io/v1`,
previous apiVersion `cert-manager.io/v1alpha2` was deprecated in cert-manager [1.4][cert-manager-1.4]
and removed in cert-manager [1.6][cert-manager-1.6],
for differences between Telegraf Operator Helm Chart 1.3.5 and Telegraf Operator Helm Chart 1.3.10 please see [this][telegraf_operator_comapare_1.3.5_and_1.3.10].

## Changed

- chore: remove support for OpenShift 4.6 and OpenShift 4.7 [#2592]
- chore: remove support for EKS 1.19 [#2592]
- chore: remove support for kOps 1.20 [#2592]
- chore(fluent-bit): update Fluent Bit Helm Chart to 0.20.9 [#2596]
- chore(telegraf-operator): update Telegraf Operator Helm Chart to 1.3.10 [#2598]
- feat: update opentelemetry-operator chart and fix progagators list in instrumentation resource [#2630]

[#2592]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2592
[#2596]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2596
[#2598]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2598
[#2630]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2630
[v2.19.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.18.1...v2.19.0
[telegraf_operator_comapare_1.3.5_and_1.3.10]: https://github.com/influxdata/helm-charts/compare/telegraf-operator-1.3.5...telegraf-operator-1.3.10
[cert-manager-1.4]: https://github.com/cert-manager/cert-manager/releases/tag/v1.4.0
[cert-manager-1.6]: https://github.com/cert-manager/cert-manager/releases/tag/v1.6.0

## [v2.18.1]

### Released 2022-10-21

### Fixed

- fix(setup):allow credentials to not be set if setup is disabled [#2572]

[#2572]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2572
[v2.18.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.18.0...v2.18.1

## [v2.18.0]

### Released 2022-10-20

See [Upgrading from v2.17 to v2.18][v2-18-migration].

This release updates Opentelemetry Operator and disables by default creation of `Instrumentation` resource.
`opentelemetry-operator.manager.env.WATCH_NAMESPACE` has no longer effect on creation of `Instrumentation` resource.
To create `Instrumentation` resource it is required to set `opentelemetry-operator.createDefaultInstrumentation` to `true` and
`opentelemetry-operator.instrumentationNamespaces` to comma separated list of namespaces where `Instrumentation` resource will be created e.g. `"ns1\,ns2"`.
This change affects you only if you have enabled opentelemetry-operator and traces with `opentelemetry-operator.enabled: true` and `sumologic.traces.enabled: true`.

### Changed

- chore: upgrade nginx to 1.23.1 [#2544]
- chore: remove support for GKE 1.20 [#2579]
- chore(opentelemetry-operator): upgrade opentelemetry-operator subchart to 0.13.0 [#2577] ([Upgrade guide][v2-18-migration])

### Fixed

- fix(openshift): fix remote write proxy - use unprivileged NGINX [#2510][#2510]

[#2510]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2510
[#2544]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2544
[#2579]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2579
[#2577]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2577
[v2.18.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.17.0...v2.18.0
[v2-18-migration]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v2-18-migration.md

## [v2.17.0]

### Released 2022-09-15

### Changed

- feat(metadata): upgrade otelcol to v0.57.2-sumo-1 [#2527]

[#2527]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2527
[v2.17.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.16.0...v2.17.0

## [v2.16.0]

### Released 2022-09-13

### Changed

- feat: add dot suffix to internal dns addresses [#2504]
- chore(tailing-sidecar-operator): upgrade to 0.3.4 [#2519]
- feat: make creation of default Instrumentation object for opentelemetry operator configurable [#2517]

[#2504]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2504
[#2519]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2519
[#2517]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2517
[v2.16.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.15.0...v2.16.0

## [v2.15.0]

### Released 2022-09-02

### Added

- feat: refactor OT log collector configuration [#2436]
- feat: store Sumo credentials for the setup Job in a Secret [#2466]
- feat: enable compaction for OT storage [#2486]

### Changed

- chore: upgrade sumologic terraform provider to 2.18 [#2399]
- chore: update kubernetes-tools to 2.12.0 [#2472]
- chore: upgrade kubernetes-setup to v3.4.0 [#2485]
- feat(otelcol/metrics/logs): adjust metric otelcol configuration [#2474], [#2479]
- chore: upgrade otelcol for metadata and events to 0.56.0-sumo-0 [#2487]

[#2466]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2466
[#2399]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2399
[#2472]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2472
[#2474]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2474
[#2479]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2479
[#2486]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2486
[#2485]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2485
[#2487]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2487
[#2436]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2436
[v2.15.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.14.1...v2.15.0

## [v2.14.1]

### Released 2022-08-01

### Changed

- chore: update Tailing Sidecar Operator subchart to 0.3.3 [#2460]

[#2460]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2460
[v2.14.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.14.0...v2.14.1

## [v2.14.0]

### Released 2022-07-29

This release changes the OpenTelemetry Collector `Traces` [exporters configuration](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v2.14.0/deploy/helm/sumologic/values.yaml#L3428)
for `otelagent` component. Collecting metrics and logs from OpenTelemetry Collector `Traces` is added.
This change affects you only if you have enabled traces with `sumologic.traces.enabled: true`.

### Changed

- feat: update fluentd to 1.14.6-sumo-5 [#2454]
- fix(tracing): loadbalancing improvements, fix metrics collection [#2457]

[#2454]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2454
[#2457]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2457
[v2.14.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.13.0...v2.14.0

## [v2.13.0]

### Released 2022-07-25

### Added

- chore: add OpenShift 4.9 to supported platforms [#2441]
- feat(openshift): add projected volumes to SecurityContextConstraints [#2443]
- chore: add OpenShift 4.10 to supported platforms [#2449]

[#2441]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2441
[#2443]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2443
[#2449]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2449
[v2.13.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.12.0...v2.13.0

## [v2.12.0]

### Released 2022-07-15

### Added

- feat(otellogs): add additional volumes and env configs [#2410]
- feat(otellogs/systemd): add support for systemd logs to otellogs [#2364]
- feat(priorityclass): add priority class for logs and traces daemonsets [#2433]
- feat(tracing): add pprof extension to the collectors [#2434]

### Changed

- feat(metadata): upgrade otelcol to v0.54.0-sumo-0 [#2422]
- feat(setup): add tolerations and affinity to setup job [#2428]

[#2410]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2410
[#2422]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2422
[#2428]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2428
[#2364]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2364
[#2433]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2433
[#2434]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2434
[v2.12.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.11.0...v2.12.0

## [v2.11.0]

### Released 2022-07-06

This release changes the OpenTelemetry Collector `Traces` service endpoint `CHART_NAME-sumologic-otelcol.NAMESPACE`
to `deprecated`. Service will still work and point to `CHART_NAME-sumologic-otelagent.NAMESPACE`.
This change affects you only if you have enabled traces with `sumologic.traces.enabled: true`.

### Added

- feat(metrics): add service metrics [#2367]
- feat(events): add experimental OT event collection [#2379], [#2407]

### Changed

- fix(metrics): remove outdated API calls [#2372]
- fix(ot-operator): shorter labels values [#2374]
- chore: update fluent-bit chart to 0.20.2 [#2375]
- chore: update falco chart to 1.18.6 [#2376]
- chore: update telegraf-operator chart to 1.3.5 [#2387]
- feat: update otellogs to 0.52.0-sumo-0 [#2338][#2338]
- chore: upgrade kubernetes terraform provider to 2.4 [#2397]
- feat(otellogs): set fingerprint_size to 17k to include timestamp for docker driver [#2325]
- chore(tracing): move k8s_tagger to otelagent [#2390]
- chore(otel-collector): update to latest release 0.54.0 [#2405]

[#2367]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2367
[#2372]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2372
[#2374]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2374
[#2375]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2375
[#2376]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2376
[#2387]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2387
[#2338]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2338
[#2397]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2397
[#2325]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2325
[#2390]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2390
[#2379]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2379
[#2405]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2405
[#2407]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2407
[v2.11.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.10.0...v2.11.0

## [v2.10.0]

### Released 2022-06-09

This release changes the OpenTelemetry Collector binary used for traces collection ([#2334]).
This change affects you only if you have enabled traces with `sumologic.traces.enabled: true`
AND you have customized the configuration in the `otelcol.config.processors.source` property.
If you have modified these properties, make sure to compare the [new configuration][source_processor_new_config]
with the [old configuration][source_processor_old_config] and apply corresponding changes to your config.

[source_processor_old_config]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v2.9.1/deploy/helm/sumologic/values.yaml#L3476-L3492
[source_processor_new_config]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v2.10.0/deploy/helm/sumologic/values.yaml#L3507-L3522

### Added

- feat(opentelemetry-operator): add opentelemetry-operator for tracing [#2172][#2172]
- feat(notes): add information about tracing receiver endpoints [#2209][#2209]

### Changed

- chore(traces): switch OTC fork to OTel Distro [#2334][#2334]
- chore: add support for Kops 1.23 [#2361][#2361]
- fix(logs/metadata): fix logs metadata for systemd [#2363]

[#2334]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2334
[#2172]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2172
[#2361]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2361
[#2363]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2363
[#2209]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2209
[v2.10.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.9.1...v2.10.0

## [v2.9.1]

### Released 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2336][#2336]

[#2336]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2336
[v2.9.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.9.0...v2.9.1

## [v2.9.0]

### Released 2022-06-01

### Added

- feat(metrics): add imagePullSecrets to remote-write-proxy [#2316]

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]
- chore: remove support for EKS with Kubernetes 1.18 [#2312][#2312]
- chore: remove support for Kops with Kubernetes 1.18 [#2313][#2313]
- chore: add support for GKE with Kubernetes 1.22 [#2314][#2314]
- chore: remove support for AKS with Kubernetes 1.19 & 1.20 [#2315][#2315]
- chore: add support for EKS with Kuberentes 1.22 [#2321][#2321]
- docs: update tested helm version to 3.8.2 [#2317][#2317]
- docs: update tested kubectl version to 1.23.6 [#2317][#2317]
- chore: change minimum required version of helm to 3.5+ [#2317][#2317]
- chore: add support for AKS with Kuberentes 1.23 [#2324][#2324]

### Fixed

- fix: set cluster field in metadata pipelines [#2284][#2284]
- fix(otellogs): set resources on Otelcol logs collector daemonset [#2291]
- fix(events): fix setting source category [#2318]

[#2284]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2284
[#2287]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2287
[#2291]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2291
[#2312]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2312
[#2313]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2313
[#2314]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2314
[#2316]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2316
[#2318]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2318
[#2315]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2315
[#2321]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2321
[#2317]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2317
[#2324]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2324
[v2.9.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.8.1...v2.9.0

## [v2.8.2][v2.8.2]

### Released 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2339][#2339]

[#2339]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2339
[v2.8.2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.8.1...v2.8.2

## [v2.8.1][v2.8.1]

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

### Fixed

- fix(otellogs): set resources on Otelcol logs collector daemonset [#2291]

[v2.8.1]:  https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.8.0...v2.8.1

## [v2.8.0]

### Released 2022-05-10

### Added

- feat(fluentd): expose extra configuration for fluentd output plugin [#2244][#2244]
- feat(monitors): the Sumo Logic monitors installation as part of the setup job [#2250][#2250], [#2274][#2274]
- feat(dashboards): the Sumo Logic dashboards installation as part of the setup job [#2268][#2268]

### Changed

- fix: use custom ServiceMonitor for Prometheus' own metrics [#2238]
- chore(deps): upgrade fluentd to 1.14.6-sumo-2 [#2245][#2245]
- feat(otellogs): upgrade to 0.49.0-sumo-0 [#2246][#2246]
- feat(metadata/otc): upgrade to v0.50.0-sumo-0 [#2251][#2251]
- chore: update Thanos to v0.25.2 [#2272][#2272]

### Fixed

- fix: set source name and category in the FluentD output for events [#2222][#2222]
- fix: proper handling of empty `sumologic.endpoint` in the setup script [#2240][#2240]
- docs: FluentD buffer size configuration [#2232][#2232]
- fix(templates): fix templates indentation [#2276][#2276]

[#2232]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2232
[#2240]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2240
[#2222]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2222
[#2238]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2238
[#2244]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2244
[#2245]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2245
[#2246]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2246
[#2250]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2250
[#2251]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2251
[#2268]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2268
[#2272]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2272
[#2274]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2274
[#2276]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2276
[v2.8.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.7.1...v2.8.0

## [v2.7.3][v2.7.3]

### Released 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2340][#2340]

[#2340]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2340
[v2.7.3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.7.2...v2.7.3

## [v2.7.2][v2.7.2]

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

[v2.7.2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.7.1...v2.7.2

## [v2.7.1]

### Released 2022-04-29

### Fixed

- fix: switch to ECR for the busybox image [#2255][#2255]
- chore: change Fluent Bit image to `public.ecr.aws/sumologic/fluent-bit:1.6.10-sumo-2`,
  it is Fluent Bit 1.6.10 with updated dependencies,
  image repository: https://github.com/SumoLogic/fluent-bit-docker-image [#2260][#2260]

[#2255]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2255
[#2260]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2260
[v2.7.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.7.1

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
- feat: remove the experimental flag for otelcol as a metadata provider [#2221][#2221]

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

## [v2.6.2][v2.6.2]

### Released 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2342][#2342]

[#2342]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2342
[v2.6.2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.6.1...v2.6.2

## [v2.6.1][v2.6.1]

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

[v2.6.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.6.0...v2.6.1

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

## [v2.5.4][v2.5.4]

### Released 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2343][#2343]

[#2343]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2343
[v2.5.4]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.5.3...v2.5.4

## [v2.5.3][v2.5.3]

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

[v2.5.3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.5.2...v2.5.3

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

## [v2.4.3][v2.4.3]

### Released 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2344][#2344]

[#2344]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2344
[v2.4.3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.4.2...v2.4.3

## [v2.4.2][v2_4_2]

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

[v2_4_2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.4.1...v2.4.2

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

## [v2.3.4][v2.3.4]

### Released 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2345][#2345]

[#2345]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2345
[v2.3.4]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.3.3...v2.3.4

## [v2.3.3][v2_3_3]

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

[v2_3_3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.3.2...v2.3.3

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
[v0.38.1-cfp-help]: https://help.sumologic.com/docs/apm/traces/advanced-configuration/filter-shape-tracing-data
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

## [v2.2.2][v2.2.2] - 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2346][#2346]

[#2346]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2346
[v2.2.2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.2.1...v2.2.2

## [v2.2.1][v2_2_1] - 2021-05-26

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

[v2_2_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.2.0...v2.2.1

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
