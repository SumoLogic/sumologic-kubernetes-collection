# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- towncrier release notes start -->

## [v4.5.0]

### Released 2024-02-21

### Added

- feat: add Sumo Logic Mock and debug features for logs and metrics [#3520]
- feat(metrics): allow customizing kubelet metrics [#3528]

### Changed

- feat(tracesgateway): move config map from values.yaml [#3525]
- feat(tracessampler): move tracessampler config map from values.yaml [#3526]
- feat(otelcolinstrumentation): move otelcol-instrumentation config from values.yaml [#3529]
- feat(sumologic-mock): support mock for cleanup process [#3532]
- feat(sumologic-mock): use secret to store `accessId` and `accessKey` during cleanup process [#3532]
- feat(sumologic-mock): support mock for setup process [#3532]
- feat(sumologic-mock): use shorter name for serviceaccount [#3533]
- chore: replace `sumologic_schema` processor with `sumologic` processor [#3534] If your values file mentions the `sumologic_schema`
  processor, you should update the name to `sumologic`.
- feat: rename sumologic-mock to mock in kubernets object names [#3536]
- chore(otelcolInstrumentation): use loadbalancing exporter when traces-gateway is disabled [#3538]
- feat(sumologic-mock): add sumologic.com/app label [#3541]
- feat(sumologic-mock): add full support to instrumentation [#3544]
- feat(sumologic-mock): add full support to events [#3545]
- feat: add support for kubernetes 1.29 for AKS [#3547]
- feat: add support for kubernetes 1.29 for EKS [#3547]
- feat: add support for kubernetes 1.29 for KOPS [#3547]
- chore(tracessampler): add persistence configuration" [#3551]
- deps: update Metrics Server subchart to `6.10.0` [#3553]
- fix(logs): do not require resources for additionalDaemonset [#3555]
- deps: update tailing-sidecar to 0.10.0 [#3556]
- deps: update opentelemetry-operator to 0.47.0 [#3557]
- chore: drop support for EKS 1.24 [#3560]
- chore: drop support for OpenShift 4.11 [#3560]

### Fixed

- fix: fix capabilities check for PodDisrutionBudget [#3514]
- fix(logs): fix global tolerations for otellogs daemonset [#3523]
- fix(debug): fix exclusion of logs scraping [#3535]
- fix(metrics): image pull secrets for metrics collector [#3539]
- fix: fix opentelemetry object for metrics collector [#3542]

[#3520]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3520
[#3528]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3528
[#3525]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3525
[#3526]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3526
[#3529]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3529
[#3532]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3532
[#3533]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3533
[#3534]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3534
[#3536]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3536
[#3538]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3538
[#3541]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3541
[#3544]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3544
[#3545]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3545
[#3547]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3547
[#3551]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3551
[#3553]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3553
[#3555]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3555
[#3556]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3556
[#3557]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3557
[#3560]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3560
[#3514]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3514
[#3523]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3523
[#3535]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3535
[#3539]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3539
[#3542]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3542
[v4.5.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v4.5.0

## [v4.4.0]

### Released 2024-01-24

### Added

- feat: add global tolerations option [#3459]
- feat: add global affinity option [#3462]
- feat(chart): run integration tests on k8s 1.29" [#3490]
- feat: add endpointslices RBAC permission [#3491]

### Changed

- deps: update falco to 3.8.6 [#3455]
- deps: update metrics server to 6.6.5 [#3456]
- deps: update opentelemetry operator to 0.46.0 [#3457], [#3515]
- feat(opentelemetry): send information about k8s version [#3460]
- chore: drop support for GKE 1.24 [#3478]
- chore: add support for GKE 1.29 [#3478]
- feat(targetallocator): expose resource configuration [#3505]
- deps: update Metrics Server to 6.8.0 [#3507]
- deps: update Falco to 3.8.7 [#3507]
- chore: update OpenTelemetry Collector to v0.92.0-sumo-0 [#3517]

### Fixed

- fix(metrics/collector): add separate image for metrics collector [#3469]

[#3459]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3459
[#3462]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3462
[#3490]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3490
[#3491]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3491
[#3455]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3455
[#3456]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3456
[#3457]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3457
[#3515]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3515
[#3460]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3460
[#3478]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3478
[#3505]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3505
[#3507]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3507
[#3517]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3517
[#3469]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3469
[v4.4.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v4.4.0

## [v4.3.1]

### Released 2023-12-14

### Fixed

- fix(metrics): use targetallocator serviceaccount created by the operator [#3447]

[#3447]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3447
[v4.3.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v4.3.1

## [v4.3.0]

### Released 2023-12-13

### Added

- feat: add description including helm version to collector [#3423]
- feat(chart): add global nodeSelector option [#3427]

### Changed

- chore: update OpenTelemetry Collector to v0.90.1-sumo-0 [#3438]
- chore: update OpenTelemetry Operator to v0.44.0 [#3441]

### Fixed

- fix(metrics): use `sumologic.metrics.excludeNamespaceRegex` instead of `sumologic.logs.container.excludeNamespaceRegex` [#3428]
- fix: fix add_timestamp behavior [#3434]

[#3423]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3423
[#3427]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3427
[#3438]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3438
[#3441]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3441
[#3428]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3428
[#3434]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3434
[v4.3.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v4.3.0

## [v4.2.0]

### Released 2023-11-27

### Breaking Changes

- chore!: upgrade otel to 0.89.0-sumo-2 [#3368] [#3414]

  Otelcol enqueue failure metrics are now only reported if they're non-zero. If you have monitors set based on the assumption that they're
  always present, you'll need to update them. Monitors installed by this Chart are unaffected.

### Added

- feat(metrics): add setting affinity for metrics collector [#3400]

### Changed

- chore: add support for:
  - EKS 1.28 [#3387]
  - EKS Fargate 1.28 [#3387]
  - OpenShift 4.14 [#3387]
  - kops 1.28 [#3387]
  - AKS 1.28 [#3387]
  - GKE v1.28 [#3403]
- chore: drop support for:
  - EKS 1.23 [#3387]
  - kops 1.23 [#3387]
  - OpenShift 4.10 [#3387]
- deps: update tailing-sidecar to 0.9.0 [#3391]
- deps: update metrics-server to `6.6.3` [#3392], [#3405], [#3416]
- deps: update falco to `v3.8.5` [#3393], [#3415]
- deps: update opentelemetry-operator to `v0.43.0` [#3394], [#3404], [#3418]
- deps: upgrade otel to 0.89.0-sumo-2 [#3414]
- deps: update telegraf operator to `v1.3.12` [#3417]

### Fixed

- fix(metrics): set nodeSelector and tolerations for target allocator [#3411]
- fix(metrics): set affinity for target allocator [#3412]

[#3368]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3368
[#3400]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3400
[#3403]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3403
[#3387]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3387
[#3391]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3391
[#3392]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3392
[#3405]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3405
[#3416]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3416
[#3393]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3393
[#3415]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3415
[#3394]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3394
[#3404]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3404
[#3418]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3418
[#3414]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3414
[#3417]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3417
[#3411]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3411
[#3412]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3412
[v4.2.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v4.2.0

## [v4.1.0]

### Released 2023-11-03

### Added

- feat: allow setting the cluster DNS domain [#3362]
- Add new service account for the otel cloudwatch collector statefulset [#3374]

### Changed

- chore: upgrade nginx image to 1.25.2-alpine-sumo-1 [#3375]

### Fixed

- fix(otel-collector): deploy collector by default on all nodes [#3348]
- use autoscaling/v2 if available on the cluster [#3366]
- fix(instrumentation): replace tools image with kubectl [#3373]

[#3362]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3362
[#3374]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3374
[#3375]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3375
[#3348]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3348
[#3366]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3366
[#3373]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3373
[v4.1.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v4.1.0

## [v4.0.1]

### Released 2023-10-25

### Fixed

- fix: downgrade otel to 0.86.0-sumo-1 [#3352]

[#3352]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3352
[v4.0.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v4.0.1

## [v4.0.0]

### Released 2023-10-20

### Migration from v3

See the [migration guide][v4_migration_guide] for details.

### Breaking Changes

- feat!: remove support for fluent-bit and fluentd [#3244]
- feat!: truncate fullname after 22 characters [#3248]
- feat(metrics)!: use otel by default [#3284]
- feat!: use OTLP sources by default [#3297]
- feat!(metrics): move extra processors after sumologic_schema [#3306]
- fix(metrics)!: drop k8s.node.name attribute [#3295]
- feat!: enable autoscaling by default [#3329]

### Added

- feat(logs): add `sumologic.logs.additionalFields` property [#3286]
- feat(metrics): add additionalServiceMonitors setting [#3292]
- feat(metrics): collect node_memory_MemAvailable_bytes [#3322]
- chore: add support for k8s 1.27 with KOPS [#3332]

### Changed

- feat(prometheus): Removing prometheus recording rules [#3211]
- feat(metrics): move app metrics filtering to metadata layer [#3232]
- chore: drop support for GKE with k8s 1.23 [#3340]

### Fixed

- fix(openshift): fix SecurityContextConstraints [#3308] [#3309] [#3310]

[#3244]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3244
[#3248]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3248
[#3284]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3284
[#3286]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3286
[#3292]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3292
[#3211]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3211
[#3232]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3232
[#3297]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3297
[#3306]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3306
[#3281]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3281
[#3289]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3289
[#3295]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3295
[#3308]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3308
[#3309]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3309
[#3310]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3310
[#3329]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3329
[#3322]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3322
[#3332]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3332
[#3340]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3340
[v4.0.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v4.0.0
[v4_migration_guide]: https://help.sumologic.com/docs/send-data/kubernetes/v4/important-changes/

## [v3.18.0]

### Released 2024-01-24

### Added

- feat: add description including helm version to collector [#3425]
- feat: add endpointslices RBAC permission [#3510]

### Changed

- chore: upgrade `fluent-bit` image from `v2.1.6` to `v2.2.0` [#3408]
- deps: upgrade `opentelemetry-operator` subchart from `v0.35.0` to `v0.44.0` [#3408] [#3439]
- deps: upgrade `falco` subchart from `v3.3.0` to `v3.8.5` [#3408] [#3445]
- deps: upgrade `fluent-bit` subchart from `v0.34.2` to `v0.40.0` [#3408]
- deps: upgrade `metrics-server` subchart from `v6.4.3` to `v6.6.3` [#3408] [#3444]
- deps: upgrade `tailing-sidecar` subchart from `v0.8.0` to `v0.9.0` [#3408]
- deps: update telegraf operator to `v1.3.12` [#3443]
- feat(opentelemetry): send information about k8s version [#3463]
- chore: update OpenTelemetry Collector to v0.92.0-sumo-0 [#3512]

### Fixed

- fix(metrics): use `sumologic.metrics.excludeNamespaceRegex` instead of `sumologic.logs.container.excludeNamespaceRegex` [#3436]

[#3425]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3425
[#3408]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3408
[#3443]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3443
[#3444]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3444
[#3445]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3445
[#3436]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3436
[#3463]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3463
[#3510]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3510
[#3512]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3512
[v3.18.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.18.0

## [v3.17.0]

### Released 2023-11-03

### Added

- Add new service account for the otel cloudwatch collector statefulset [#3374]

### Changed

- chore: drop support for GKE with k8s 1.23 [#3342]
- chore: upgrade nginx image to 1.25.2-alpine-sumo-1 [#3375]

### Fixed

- fix(otel-collector): deploy collector by default on all nodes [#3348]
- use autoscaling/v2 if available on the cluster [#3367]
- fix(instrumentation): replace tools image with kubectl [#3373]

[#3342]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3342
[#3367]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3367
[v3.17.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.17.0

## [v3.16.2]

### Released 2023-10-25

### Fixed

- fix: downgrade otel to 0.86.0-sumo-1 [#3352]

[v3.16.2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.16.2

## [v3.16.1]

### Released 2023-10-20

### Changed

- chore: upgrade otel to 0.87.0-sumo-0 [#3334]

[#3334]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3334
[v3.16.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.16.1

## [v3.16.0]

### Released 2023-10-18

### Changed

- chore: update setup job to `v3.11.0` [#3320]
- feat(metrics): allow overriding metrics collector configuration [#3314]

### Fixed

- fix(logs)!: move JSON parsing after user-defined processors [#3281]

  The log body will now always be a string if accessed in extra processors. Users who want to access specific fields in their parsed JSON
  log should explicitly call ParseJSON in their processor definition.

- fix(metrics): decompose OTLP histograms [#3289]
- fix(metrics): drop stale datapoints [#3318]
- fix: fix Otel Operator installation with Helm 3.13 [#3321]
- fix(metrics): kube-state-metrics pod metadata [#3323]

[#3314]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3314
[#3320]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3320
[#3318]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3318
[#3321]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3321
[#3323]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3323
[v3.16.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.16.0

## [v3.15.0]

### Released 2023-09-18

### Added

- feat(metrics): add ability to use OTLP source [#2949]
- feat: add extraProcessor for kubelet and systemd [#3251]

### Changed

- chore: upgrade nginx iamge to `1.25.2-alpine` [#3252]
- chore: update setup image to v3.10.0 [#3255]
- chore: upgrade otel to 0.85.0-sumo-0 [#3262]

### Fixed

- fix(fluent-bit): set Time_Keep to On in containerd parser" [#3227]
- feat: use either minAvailable or maxUnavailable for logs pdb [#3231]
- fix: disable keep-alives for internal traffic [#3267]

[#2949]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2949
[#3251]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3251
[#3252]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3252
[#3255]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3255
[#3262]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3262
[#3227]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3227
[#3231]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3231
[#3267]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3267
[v3.15.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.15.0

## [v3.14.0]

### Released 2023-09-01

### Added

- feat(metrics/collector): add batching [#3229]
- feat(logs): add option to preserve `time` attribute [#3234]

[#3229]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3229
[#3234]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3234
[v3.14.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.14.0

## [v3.13.0]

### Released 2023-08-21

### Added

- feat(metrics/collector): support partial histograms [#3192]
- feat(metrics/collector) allow setting global scrape interval [#3203]
- feat(metrics/collector): add default App metric filters [#3204]
- feat(events): add sourceCategoryReplaceDash [#3214]
- feat(metrics/collector): support remote write proxy [#3221]
- feat(metrics/collector): allow setting allocation strategy [#3226]

### Changed

- chore: upgrade opentelemetry-operator chart to 0.35.0 [#3203]
- feat(metrics/collector): only select monitors from the release by default [#3207]
- feat(metrics/collector): filter scrape configs in target allocator [#3208]
- chore: drop support for AKS 1.24 [#3209]
- chore: upgrade otel to 0.83.0-sumo-0 [#3215]
- feat(metrics/collector): adjust resources and autoscaling [#3219]
- feat(metrics/collector): set stability to Beta [#3223]

### Fixed

- fix(metrics): don't collect internal Telegraf metrics [#3193]
- feat: fix fluentd hpa template generation [#3194]
- fix(metrics/collector): scrape configs disabled [#3195]
- fix(logs): fix text format for otlp source [#3212]
- fix(metrics/collector): explicitly set OT image [#3225]

[#3192]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3192
[#3203]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3203
[#3204]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3204
[#3214]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3214
[#3221]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3221
[#3226]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3226
[#3207]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3207
[#3208]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3208
[#3209]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3209
[#3215]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3215
[#3219]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3219
[#3223]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3223
[#3193]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3193
[#3194]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3194
[#3195]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3195
[#3212]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3212
[#3225]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3225
[v3.13.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.13.0

## [v3.12.1]

### Released 2023-08-10

### Fixed

- fix: disable zstd compression internally [#3197]

[v3.12.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.12.1

## [v3.12.0]

### Released 2023-08-07

### Added

- feat(metrics/collector): allow disabling metrics from annotated Pods [#3190]

### Changed

- chore: update otelcol to 0.82.0-sumo-0 [#3176]
- feat: add support for multiple multiline detection [#3181]

### Fixed

- fix(metrics): add job attribute to Prometheus annotation metrics [#3178]
- fix(otellogs): fix configuration for filelog/container to use default settings for fingerprint_size on k8s >=1.24 [#3185]

[#3190]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3190
[#3176]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3176
[#3181]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3181
[#3178]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3178
[#3185]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3185
[v3.12.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.12.0

## [v3.11.1]

### Released 2023-08-10

### Fixed

- fix: disable zstd compression internally [#3197]

[#3197]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3197
[v3.11.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.11.1

## [v3.11.0]

### Released 2023-07-28

### Added

- docs(prometheus): Added a section on prometheus sharding [#3140]
- feat(metrics/collector): collect metrics from annotated Pods [#3162]

### Changed

- chore: add support for EKS (fargate) 1.27 [#3136]
- chore: upgrade otel to 0.81.0-sumo-0 [#3139]
- chore(chart): update fluent-bit to 2.1.6 [#3142]
- chore(chart): update falco chart to 3.3.0; falco to 0.35.1 [#3143]
- chore(chart): update tailing sidecar operator to 0.8.0 [#3145]
- chore(chart): update metrics-server chart to 6.4.3 [#3146]
- chore: add support for GKE 1.27 [#3148]
- chore: add support for AKS 1.27 [#3149]
- chore: use zstd compression for internal otlp data [#3156]
- feat(metrics): do not filter in default remote write definitions [#3157]
- feat: add hpa for traces-gateway and otelcol-instrumentation [#3159]
- feat(metrics): disable default Prometheus rules [#3160] Note: If you had customized metrics collection to forward some of these metrics,
  you can re-enable the relevant rules under `kube-prometheus-stack.defaultRules`.
- feat(metrics): remove collection metrics remote write [#3161]
- chore: update fluentd image to 1.16.2-sumo-0 [#3165]
- feat: fix serviceMonitor for additional daemonsets [#3166]

### Fixed

- fix(metrics/collector): drop k8s labels [#3141]
- feat(helm): change the minimum version for using autoscaling/v2 api to 1.23 [#3155]
- fix(helm/metrics): exclude namespace if collectionMonitoring is disabled [#3170]
- fix(metrics): don't forward duplicate metrics from annotated Pods [#3171]
- fix(helm): fix cloudwatch collector configuration for disabled persistence [#3172]

[#3140]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3140
[#3162]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3162
[#3136]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3136
[#3139]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3139
[#3142]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3142
[#3143]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3143
[#3145]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3145
[#3146]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3146
[#3148]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3148
[#3149]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3149
[#3156]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3156
[#3157]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3157
[#3159]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3159
[#3160]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3160
[#3161]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3161
[#3165]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3165
[#3166]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3166
[#3141]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3141
[#3155]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3155
[#3170]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3170
[#3171]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3171
[#3172]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3172
[v3.11.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.11.0

## [v3.10.0]

### Released 2023-07-06

### Added

- feat(logs): add ability to use OTLP source [#3040]
- feat: add autoscaling to metrics collector [#3082]
- feat: add serviceMonitor for metrics collector [#3084]
- feat(events): add ability to use OTLP source [#3093]
- feat(traces): add ability to use OTLP source [#3094]
- feat(metrics): add selectors for Prometheus CRs to otel metrics collector [#3096]
- chore: add support for OpenShift 4.13 [#3104]
- chore: add support for EKS 1.27 [#3104]
- feat(metrics): set securityContext for metrics collector [#3119]
- feat(metrics/collector): allow disabling cadvisor and kubelet metrics [#3121], [#3133]
- feat(metrics): collect full etcd histogram metrics [#3130]

### Changed

- feat: unify anti-affinity configuration [#3085]
- chore: upgrade otel to 0.79.0-sumo-0 [#3087]
- feat(helm): add missing options for experimental opentelemetry metrics" [#3092]
- feat(helm): move relabelling in prometheus from remoteWrites to serviceMonitors [#3103]
- chore: update metrics-server to 6.3.1 [#3110]
- chore: update Telegraf Operator to v1.3.11 [#3111]
- chore: update Fluent Bit Helm Chart to v0.31.0 [#3117]
- feat: fix service monitors for node-exporter and kube-state-metrics [#3118]
- feat(metrics): split metadata extraction from otel collector [#3122]
- chore: upgrade opentelemetry-operator chart to 0.33.0 [#3125]
- feat(helm/metrics): route metrics using job attribute instead of endpoint [#3126]
- chore: update opentlemetry-operator auto-instrumentation images [#3129]
- fix(metrics/collector): drop scrape\_\* metrics [#3131]

### Fixed

- fix(metrics): upgrade kube-state-metrics to 2.7.0 [#3086]
- fix(otelcloudwatch): Fixing PVC name for the cloudwatch logs collector [#3099]
- fix(metrics-server): add double dashes to extra arguments [#3109]

[#3040]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3040
[#3082]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3082
[#3084]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3084
[#3093]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3093
[#3094]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3094
[#3096]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3096
[#3104]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3104
[#3119]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3119
[#3121]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3121
[#3133]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3133
[#3130]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3130
[#3085]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3085
[#3087]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3087
[#3092]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3092
[#3103]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3103
[#3110]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3110
[#3111]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3111
[#3117]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3117
[#3118]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3118
[#3122]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3122
[#3125]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3125
[#3126]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3126
[#3129]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3129
[#3131]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3131
[#3086]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3086
[#3099]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3099
[#3109]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3109
[v3.10.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.10.0

## [v3.9.1]

### Released 2023-06-29

### Changed

- chore: Upgrade kubernetes setup to v3.9.0 [#3098]

[#3098]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3098
[v3.9.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.9.1

## [v3.9.0]

### Released 2023-06-14

### Breaking Changes

- feat(metrics)!: disable remote write proxy access logs by default [#3071]

  The logs can be enabled by setting`sumologic.metrics.remoteWriteProxy.config.enableAccessLogs` to `true`.

### Added

- fix: otelcol logs json_merge where message bodies are only sometimes json [#3050]

### Changed

- feat: override namespace from values [#3068]
- chore: upgrade Fluent Bit to 2.1.4 [#3075] This change may break some custom Fluent Bit configurations.

  A temporary workaround is to switch back to the 1.6.10-sumo-3 image. We recommend updating the custom configuration, or better yet,
  switching to Otel.

- feat: pass extra arguments to otel logs statefulset [#3076]
- Reordering HPA metrics to match HPA ordering [#3078]
- chore: drop support for k8s 1.22 [#3081]

### Fixed

- fix(logs): parse json in fluent bit pipeline [#3063]
- fix(logs): use longer fingerprint only on K8s <1.24 [#3070]

[#3071]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3071
[#3050]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3050
[#3068]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3068
[#3075]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3075
[#3076]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3076
[#3078]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3078
[#3081]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3081
[#3063]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3063
[#3070]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3070
[v3.9.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.9.0

## [v3.8.0]

### Released 2023-05-22

### Added

- feat(metrics): add experimental otel metrics collector [#2988]
- feat: allow setting otelcol image globally [#3051]
- feat: add optional fips suffix for otelcol images [#3056]
- feat(EKS Fargate): Add multiline support to EKS Fargate [#3059]
- feat(metric): allow disabling remote write proxy access logs [#3062]

### Changed

- feat(pvc-cleaner): run pvcCleaner as non-root user [#3055]

### Fixed

- fix: warn about release name length [#3054]

[#2988]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2988
[#3051]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3051
[#3056]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3056
[#3059]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3059
[#3062]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3062
[#3055]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3055
[#3054]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3054
[v3.8.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.8.0

## [v3.7.0]

### Released 2023-05-11

### Added

- chore: add support for GKE 1.26 [#3047]
- chore: add support for EKS 1.26 [#3047]

### Changed

- feat: use timestamp as message time if exists [#3039]
- chore: upgrade otelcol to 0.76.1-sumo-0 [#3041]
- chore: drop support for OpenShift 4.8 and 4.9 [#3043]
- chore: drop support for GKE 1.22 [#3043]

### Fixed

- fix(logs): systemd logs with otel and Fluent Bit [#3042]

[#3047]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3047
[#3039]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3039
[#3041]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3041
[#3043]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3043
[#3042]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3042
[v3.7.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.7.0

## [v3.6.1]

### Released 2023-05-05

### Fixed

- fix: fix setting proxy in templates [#3022]

[#3022]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3022
[v3.6.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.6.1

## [v3.6.0]

### Released 2023-05-04

### Added

- Added the otel cloudwatch statefulset logs collector (fargate) with documentation updates [#2982]

### Changed

- chore: add support for KOPS 1.26, EKS 1.25, AKS 1.26, OpenShift 4.12; remove support for GKE 1.21, EKS 1.21, AKS 1.23 [#2969]
- chore: update setup image to 3.8.0 [#3000]
- chore: upgrade opentelemetry-operator chart to 0.27.0 [#3008]

### Fixed

- fix: fix logs pipeline if systemd is disabled [#3001]

[#2982]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2982
[#2969]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2969
[#3000]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3000
[#3008]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3008
[#3001]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3001
[v3.6.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.6.0

## [v3.5.0]

### Released 2023-04-14

### Changed

- chore: upgrade fluent-bit chart to 0.25.0 [#2968]
- chore: upgrade nginx image to 1.23.3-alpine [#2970]
- chore: upgrade tailing-sidecar to 0.7.0 [#2971]
- feat: stop using sumologic kubernetes tools for pvc cleaner [#2973], [#2983]

### Fixed

- fix(otelllogs): fix disabling otellogs metrics collection [#2958]
- fix(pvcCleaner): don't create resources when pvcCleaner is disabled [#2962]
- fix(otellogs): configure imagePullSecrets for otellogs [#2984]

[#2968]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2968
[#2970]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2970
[#2971]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2971
[#2973]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2973
[#2983]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2983
[#2958]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2958
[#2962]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2962
[#2984]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2984
[v3.5.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.5.0

## [v3.4.0]

### Released 2023-03-27

### Added

- feat: Add extraPorts parameter to metadata.logs.statefulset [#2924]

### Changed

- chore(metrics): remove deprecated coredns and etcd metrics [#2899]
- chore: upgrade otelcol to 0.73.0-sumo-1 [#2927]
- chore: bump setup image to 3.7.0 [#2950]

### Fixed

- fix(metrics): drop cadvisor container metrics without metadata [#2918]
- fix(logs): reduce the queue size of the logs collector [#2923]
- fix(cleanup): proxy env vars updated. fixes #2928 [#2932]
- fix(metrics): drop apiserver request histograms [#2952]
- fix(setup): do not create field which already exist [#2953]

[#2924]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2924
[#2899]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2899
[#2927]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2927
[#2950]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2950
[#2918]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2918
[#2923]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2923
[#2932]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2932
[#2952]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2952
[#2953]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2953
[v3.4.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.4.0

## [v3.3.0]

### Released 2023-03-01

### Added

- feat(chart): add `pvcCleaner` [#2796]

### Changed

- chore(otoperator): update opentelemetry operator, add instrumentation customization [#2894] Changed [#2894] OpenTelemetry-Operator was
  updated to [v0.24.0]. New configuration flags were added:

  - Flags to control metrics/traces export from specific instrumentation in `Instrumentation` resource.
    - `opentelemetry-operator.instrumentation.dotnet.metrics.enabled`
    - `opentelemetry-operator.instrumentation.dotnet.traces.enabled`
    - `opentelemetry-operator.instrumentation.java.metrics.enabled`
    - `opentelemetry-operator.instrumentation.java.traces.enabled`
    - `opentelemetry-operator.instrumentation.python.metrics.enabled`
    - `opentelemetry-operator.instrumentation.python.traces.enabled`
  - Flags to set CPU and Memory requests and limits for OpenTelemetry-Operator
    - `opentelemetry-operator.manager.resources.limits.cpu`
    - `opentelemetry-operator.manager.resources.limits.memory`
    - `opentelemetry-operator.manager.resources.requests.cpu`
    - `opentelemetry-operator.manager.resources.requests.memory`

  > **Warning** > This action is required only if you have enabled `opentelemetry-operator` with `opentelemetry-operator.enabled: true`.
  > Please delete the following resources before update of the chart:

  - `opentelemetry-operator-validating-webhook-configuration` (validatingwebhookconfiguration)
  - `opentelemetry-operator-mutating-webhook-configuration` (mutatingwebhookconfiguration)
  - `opentelemetry-operator-controller-manager-metrics-service` (service)
  - `opentelemetry-operator-webhook-service` (service)
  - `opentelemetry-operator-controller-manager` (deployment)

  [v0.24.0]: https://github.com/open-telemetry/opentelemetry-helm-charts/releases/tag/opentelemetry-operator-0.24.0

- chore(metrics): remove deprecated apiserver metrics [#2898]

### Fixed

- feat(servicemonitor): fix instrumentation scraping, add tests [#2892]
- fix(busybox): use exact version of busybox img [#2893]
- fix: collect the right kube-scheduler metrics [#2896]

[#2796]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2796
[#2894]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2894
[#2898]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2898
[#2892]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2892
[#2893]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2893
[#2896]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2896
[v3.3.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.3.0

## [v3.2.0]

### Released 2023-02-16

### Changed

- feat: disable otel storage compaction on start [#2870]
- chore: upgrade otelcol to 0.71.0-sumo-0 [#2872]
- feat: use /tmp for otel storage compaction [#2873]
- chore: bump setup image to 3.6.0 [#2882]

### Fixed

- feat(instrumentation): scrape label added and updated [#2875]

[#2870]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2870
[#2872]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2872
[#2873]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2873
[#2882]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2882
[#2875]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2875
[v3.2.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/v3.2.0

## [v3.1.1]

### Released 2023-02-13

### Fixed

- fix(logs): fix container attribute [#2863]

  Fixes [#2862] Logs from two different containers of one pod show up in Sumo as coming from one of the containers

- fix(setup): fix error when creating fields [#2866]

  Fixes [#2865] Setup job fails trying to create fields that already exist

[#2863]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2863
[#2862]: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/2862
[#2866]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2866
[#2865]: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/2865
[v3.1.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v3.1.0...v3.1.1

## [v3.1.0]

### Released 2023-02-09

### Changed

- chore: add support for EKS 1.24 [#2831]
- chore: add support for GKE 1.24 [#2832]
- chore: remove support for KOPS 1.21 [#2848]
- chore: add support for KOPS 1.25 [#2848]
- chore: add support for AKS 1.25 [#2848]
- chore: add support for GKE 1.25 [#2848]
- chore: add support for Openshift 4.11 [#2848]
- feat(otelcol): add max size in batch processors [#2839]
- chore: bump sumologic-kubernetes-setup image to 3.6.0 and kube-state-metrics image to 2.7.0 [#2857]

[#2831]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2831
[#2832]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2832
[#2839]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2839
[#2848]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2848
[#2857]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2857
[v3.1.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v3.0.0...v3.1.0

## [v3.0.1]

### Released 2023-02-09

### Fixed

- fix(logs): fix excluding logs by container, namespace, node, pod regex [#2853]

[#2853]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2853
[v3.0.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v3.0.0...v3.0.1

## [v3.0.0]

### Released 2023-01-20

### Migration from v2

See the [migration guide][v3_migration_guide] for details.

### Added

- feat(logs): allow setting daemonset labels and annotations [#2811]

[#2811]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2811
[v3.0.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v3.0.0-rc.0...v3.0.0

## [v3.0.0-rc.0]

### Released 2023-01-19

### Added

- feat(logs): add `sumologic.logs.container.otelcol.extraProcessors` [#2790]

### Changed

- feat(metrics): add `sumologic.metrics.otelcol.extraProcessors` [#2724] [#2780]
- feat: add otellogs.additionDaemonSets configuration [#2750]
- chore: upgrade Fluentd to v1.15.3-sumo-0 [#2745]
  - This also upgrades Ruby from `v2.7` to `v3.1` and some other dependencies. See [v1.15.3-sumo-0] for more.
- feat: adjust average utilization for metadata autoscaling [#2744]
- chore: upgrade otelcol to 0.69.0-sumo-0 [#2755] [#2791]
- chore: remove support for AKS 1.22 [#2756]
- feat(logs): add daemonset and statefulset to default fields [#2766]
- feat: collect metrics from otelcol event collector [#2754]
- feat: add option to specify additionalEndpoints for metrics [#2788]
- chore: upgrade kubernetes-setup to v3.5.0 [#2785]
- feat(logs): parse JSON logs [#2773]
- feat(logs): add format setting [#2794]
- chore: remove support for EKS 1.20 [#2807]

### Fixed

- fix(logs): remove unnecessary metadata [#2761]
- fix(logs): make `excludeHostRegex` consistent between Otelcol and Fluentd [#2771]
  - The `sumologic.logs.container.excludeHostRegex` should filter on the Kubernetes node name, to be consistent with Fluentd and chart v2.
- fix(logs): correctly handle newlines [#2805]
  - Fixes [#2802], [#2803]
- fix(logs): make built-in metadata consistent between fluentd and otel [#2801]

[#2724]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2724
[#2745]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2745
[#2750]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2750
[#2744]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2744
[#2755]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2755
[#2756]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2756
[#2761]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2761
[#2766]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2766
[#2754]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2754
[#2771]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2771
[#2780]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2780
[#2788]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2788
[#2785]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2785
[#2791]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2791
[#2773]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2773
[#2790]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2790
[#2802]: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/2802
[#2803]: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/2803
[#2805]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2805
[#2801]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2801
[#2794]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2794
[#2807]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2807
[v1.15.3-sumo-0]: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/releases/tag/v1.15.3-sumo-0
[v3_migration_guide]: https://help.sumologic.com/docs/send-data/kubernetes/v3/important-changes/
[v3.0.0-rc.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v3.0.0-beta.0...v3.0.0-rc.0

## [v3.0.0-beta.1]

### Released 2023-01-02

### Changed

- chore: upgrade Fluent Bit to v1.6.10-sumo-3 [#2712]
- chore: upgrade otelcol to 0.66.0-sumo-0 [#2686] [#2687] [#2692] [#2693]
- feat(otellogs): read from end [#2710]
- fix(openshift): changed allowed fsgroups in SecurityContextConstraints [#2717]
- fix(openshift): set securityContexts for otelcol-logs-collector [#2717]
- fix: obey proxy settings in otelcol [#2719]
- feat(metrics): simplify custom application metrics [#2716]
- chore: downgrade kube-prometheus-stack to 40.5.0 [#2723]

[#2686]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2686
[#2687]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2687
[#2693]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2693
[#2692]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2692
[#2710]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2710
[#2712]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2712
[#2717]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2717
[#2719]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2719
[#2716]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2716
[#2723]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2723
[v3.0.0-beta.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v3.0.0-beta.0...v3.0.0-beta.1

## [v3.0.0-beta.0]

### Released 2022-12-02

If you use custom configuration for Telegraf Operator Helm Chart with cert-manager enabled (`telegraf-operator.certManager.enable=true`)
please note that in this release Telegraf Operator Helm Chart is changed to 1.3.10 which uses the cert-manager apiVersion
`cert-manager.io/v1`, previous apiVersion `cert-manager.io/v1alpha2` was deprecated in cert-manager [1.4][cert-manager-1.4] and removed in
cert-manager [1.6][cert-manager-1.6], for differences between Telegraf Operator Helm Chart 1.3.5 and Telegraf Operator Helm Chart 1.3.10
please see [this][telegraf_operator_comapare_1.3.5_and_1.3.10].

### Breaking Changes

- fix(logs): prevent Fluent Bit from doing metadata enrichment [#2512]
- chore(kube-prometheus-stack): update kube-prometheus-stack chart to 42.1.0 [#2446] [#2651]
- feat(metrics)!: disable Thanos by default [#2514]
- fix(fluentd): Removing PodSecurityPolicy for fluentd [#2605]
- feat!: refactor event collection configuration [#2444]
- fix(logs): configure fluentbit to send data to metadata-logs [#2610]
- feat(logs): Changing the default logs metadata provider to otel [#2621]
- chore!: remove replacing values in configuration marked by 'replace' suffix [#2615]
- feat(metrics): service name change and switching the metrics provider default to otelcol [#2627]
- feat(logs)!: simplify metadata configuration [#2626]
- feat(metrics)!: simplify metadata configuration [#2622]
- feat(events)!: add config.merge option [#2643]
- feat(terraform)!: expect load_config_file to be not set [#2648]
- feat(otellogs)!: add config.merge option [#2652]
- chore!: upgrade falco to 2.4.2 [#2659]
- chore!: move parameters from `fluentd.logs.containers` to `sumologic.logs.container` [#2635]
  - move `fluentd.logs.containers.sourceHost` to `sumologic.logs.container.sourceHost`
  - move `fluentd.logs.containers.sourceName` to `sumologic.logs.container.sourceName`
  - move `fluentd.logs.contianers.sourceCategory` to `sumologic.logs.container.sourceCategory`
  - move `fluentd.logs.containers.sourceCategoryPrefix` to `sumologic.logs.container.sourceCategoryPrefix`
  - move `fluentd.logs.contianers.sourceCategoryReplaceDash` to `sumologic.logs.container.sourceCategoryReplaceDash`
  - move `fluentd.logs.containers.excludeContainerRegex` to `sumologic.logs.container.excludeContainerRegex`
  - move `fluentd.logs.containers.excludeHostRegex` to `sumologic.logs.container.excludeHostRegex`
  - move `fluentd.logs.containers.excludeNamespaceRegex` to `sumologic.logs.container.excludeNamespaceRegex`
  - move `fluentd.logs.containers.excludePodRegex` to `sumologic.logs.container.excludePodRegex`
  - move `fluentd.logs.containers.sourceHost` to `sumologic.logs.container.sourceHost`
  - move `fluentd.logs.containers.perContainerAnnotationsEnabled` to `sumologic.logs.container.perContainerAnnotationsEnabled`
  - move `fluentd.logs.containers.perContainerAnnotationPrefixes` to `sumologic.logs.container.perContainerAnnotationPrefixes`
- chore!: move parameters from `fluentd.logs.kubelet` to `sumologic.logs.kubelet` [#2635]
  - move `fluentd.logs.kubelet.sourceName` to `sumologic.logs.kubelet.sourceName`
  - move `fluentd.logs.kubelet.sourceCategory` to `sumologic.logs.kubelet.sourceCategory`
  - move `fluentd.logs.kubelet.sourceCategoryPrefix` to `sumologic.logs.kubelet.sourceCategoryPrefix`
  - move `fluentd.logs.kubelet.sourceCategoryReplaceDash` to `sumologic.logs.kubelet.sourceCategoryReplaceDash`
  - move `fluentd.logs.kubelet.excludeFacilityRegex` to `sumologic.logs.kubelet.excludeFacilityRegex`
  - move `fluentd.logs.kubelet.excludeHostRegex` to `sumologic.logs.kubelet.excludeHostRegex`
  - move `fluentd.logs.kubelet.excludePriorityRegex` to `sumologic.logs.kubelet.excludePriorityRegex`
  - move `fluentd.logs.kubelet.excludeUnitRegex` to `sumologic.logs.kubelet.excludeUnitRegex`
- chore!: move parameters from `fluentd.logs.systemd` to `sumologic.logs.systemd` [#2635]
  - move `fluentd.logs.systemd.sourceName` to `sumologic.logs.systemd.sourceName`
  - move `fluentd.logs.systemd.sourceCategory` to `sumologic.logs.systemd.sourceCategory`
  - move `fluentd.logs.systemd.sourceCategoryPrefix` to `sumologic.logs.systemd.sourceCategoryPrefix`
  - move `fluentd.logs.systemd.sourceCategoryReplaceDash` to `sumologic.logs.systemd.sourceCategoryReplaceDash`
  - move `fluentd.logs.systemd.excludeFacilityRegex` to `sumologic.logs.systemd.excludeFacilityRegex`
  - move `fluentd.logs.systemd.excludeHostRegex` to `sumologic.logs.systemd.excludeHostRegex`
  - move `fluentd.logs.systemd.excludePriorityRegex` to `sumologic.logs.systemd.excludePriorityRegex`
  - move `fluentd.logs.systemd.excludeUnitRegex` to `sumologic.logs.systemd.excludeUnitRegex`
- chore!: move parameters from `fluentd.logs.default` to `sumologic.logs.defaultFluentd` [#2635]
  - move `fluentd.logs.default.sourceName` to `sumologic.logs.defaultFluentd.sourceName`
  - move `fluentd.logs.default.sourceCategory` to `sumologic.logs.defaultFluentd.sourceCategory`
  - move `fluentd.logs.default.sourceCategoryPrefix` to `sumologic.logs.defaultFluentd.sourceCategoryPrefix`
  - move `fluentd.logs.default.sourceCategoryReplaceDash` to `sumologic.logs.defaultFluentd.sourceCategoryReplaceDash`
  - move `fluentd.logs.default.excludeFacilityRegex` to `sumologic.logs.defaultFluentd.excludeFacilityRegex`
  - move `fluentd.logs.default.excludeHostRegex` to `sumologic.logs.defaultFluentd.excludeHostRegex`
  - move `fluentd.logs.default.excludePriorityRegex` to `sumologic.logs.defaultFluentd.excludePriorityRegex`
  - move `fluentd.logs.default.excludeUnitRegex` to `sumologic.logs.defaultFluentd.excludeUnitRegex`
- chore!: upgrade metrics-server to v6.2.4 [#2660] [#2664]
- chore!: upgrade tailing-sidecar-operator to v0.5.5 [#2661]
- feat(logs)!: switch from Fluent Bit to Otelcol as default logs collector [#2639]
- feat(events)!: switch from Fluentd to Otelcol as default events collector [#2640]
- feat!: change instrumentation related k8s objects [#2647]
  - move parameters from `otelagent.*` to `otelcolInstrumentation.*`
  - move parameters from `otelgateway.*` to `tracesGateway.*`
  - move parameters from `otelcol.*` to `tracesSampler.*`
- feat: enable metrics and traces collection from instrumentation by default [#2154]
  - change parameter `sumologic.traces.enabled` default value from `false` to `true`

### Changed

- feat: enable remote write proxy by default [#2483]
- chore: update kubernetes-tools to 2.13.0 [#2515]
- feat(metadata): upgrade otelcol to v0.57.2-sumo-1 [#2526]
- docs: update documentation around additionalRemoteWrite for kube-prometheus-stack [#2549]
- chore(opentelemetry-operator): upgrade opentelemetry-operator subchart to 0.13.0 [#2561]
- chore: remove support for GKE 1.20 [#2578]
- chore: remove support for EKS 1.19 [#2587]
- chore: remove support for kOps 1.20 [#2591]
- chore(fluent-bit): update Fluent Bit Helm Chart to 0.21.3 [#2650]
- chore(telegraf-operator): update Telegraf Operator Helm Chart to 1.3.10 [#2597]
- feat(chart): restrict permissions for setup and cleanup jobs [#2599]
- feat: add parameter to configure additional Prometheus remote writes [#2611]
- docs: rename user-provided config from values.yaml to user-values.yaml [#2619]
- feat: update opentelemetry-operator chart and fix progagators list in instrumentation resource [#2628]
- feat: upgrade node-exporter to v1.4.0 [#2649]
- feat: drop migration script for v1 [#2654]

### Fixed

- fix: default.metrics source is not imported when metrics are disabled and traces are enabled [#2547]
- fix(cleanup): fix cleanup job [#2600]
- fix(setup): add permission to modify secrets [#2653]

[#2154]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2154
[#2483]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2483
[#2512]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2512
[#2514]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2514
[#2446]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2446
[#2515]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2515
[#2526]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2526
[#2547]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2547
[#2549]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2549
[#2561]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2561
[#2578]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2578
[#2587]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2587
[#2591]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2591
[#2597]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2597
[#2599]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2599
[#2600]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2600
[#2605]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2605
[#2611]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2611
[#2444]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2444
[#2610]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2610
[#2619]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2619
[#2621]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2621
[#2615]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2615
[#2628]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2628
[#2627]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2627
[#2626]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2626
[#2622]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2622
[#2643]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2643
[#2651]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2651
[#2648]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2648
[#2649]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2649
[#2654]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2654
[#2652]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2652
[#2659]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2659
[#2635]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2635
[#2660]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2660
[#2661]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2661
[#2639]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2639
[#2640]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2640
[#2647]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2647
[#2664]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2664
[#2653]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2653
[v3.0.0-beta.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.17.0...v3.0.0-beta.0

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

If you use custom configuration for Telegraf Operator Helm Chart with cert-manager enabled (`telegraf-operator.certManager.enable=true`)
please note that in this release Telegraf Operator Helm Chart is changed to 1.3.10 which uses the cert-manager apiVersion
`cert-manager.io/v1`, previous apiVersion `cert-manager.io/v1alpha2` was deprecated in cert-manager [1.4][cert-manager-1.4] and removed in
cert-manager [1.6][cert-manager-1.6], for differences between Telegraf Operator Helm Chart 1.3.5 and Telegraf Operator Helm Chart 1.3.10
please see [this][telegraf_operator_comapare_1.3.5_and_1.3.10].

### Changed

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
[telegraf_operator_comapare_1.3.5_and_1.3.10]:
  https://github.com/influxdata/helm-charts/compare/telegraf-operator-1.3.5...telegraf-operator-1.3.10
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
`opentelemetry-operator.manager.env.WATCH_NAMESPACE` has no longer effect on creation of `Instrumentation` resource. To create
`Instrumentation` resource it is required to set `opentelemetry-operator.createDefaultInstrumentation` to `true` and
`opentelemetry-operator.instrumentationNamespaces` to comma separated list of namespaces where `Instrumentation` resource will be created
e.g. `"ns1\,ns2"`. This change affects you only if you have enabled opentelemetry-operator and traces with
`opentelemetry-operator.enabled: true` and `sumologic.traces.enabled: true`.

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

This release changes the OpenTelemetry Collector `Traces`
[exporters configuration](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v2.14.0/deploy/helm/sumologic/values.yaml#L3428)
for `otelagent` component. Collecting metrics and logs from OpenTelemetry Collector `Traces` is added. This change affects you only if you
have enabled traces with `sumologic.traces.enabled: true`.

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

This release changes the OpenTelemetry Collector `Traces` service endpoint `CHART_NAME-sumologic-otelcol.NAMESPACE` to `deprecated`. Service
will still work and point to `CHART_NAME-sumologic-otelagent.NAMESPACE`. This change affects you only if you have enabled traces with
`sumologic.traces.enabled: true`.

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

This release changes the OpenTelemetry Collector binary used for traces collection ([#2334]). This change affects you only if you have
enabled traces with `sumologic.traces.enabled: true` AND you have customized the configuration in the `otelcol.config.processors.source`
property. If you have modified these properties, make sure to compare the [new configuration][source_processor_new_config] with the [old
configuration][source_processor_old_config] and apply corresponding changes to your config.

[source_processor_old_config]:
  https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v2.9.1/deploy/helm/sumologic/values.yaml#L3476-L3492
[source_processor_new_config]:
  https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/v2.10.0/deploy/helm/sumologic/values.yaml#L3507-L3522

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

### Released 2022-05-26

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

### Fixed

- fix(otellogs): set resources on Otelcol logs collector daemonset [#2291]

[v2.8.1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.8.0...v2.8.1

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

### Released 2022-05-26

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

[v2.7.2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.7.1...v2.7.2

## [v2.7.1]

### Released 2022-04-29

### Fixed

- fix: switch to ECR for the busybox image [#2255][#2255]
- chore: change Fluent Bit image to `public.ecr.aws/sumologic/fluent-bit:1.6.10-sumo-2`, it is Fluent Bit 1.6.10 with updated dependencies,
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

### Released 2022-05-26

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
- chore: remove support for OpenShift 4.6 and OpenShift 4.7 [#2586]

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
[#2586]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2586
[v2.6.0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.6.0

## [v2.5.4][v2.5.4]

### Released 2022-06-02

### Changed

- chore: update metrics-server to 5.11.9 [#2343][#2343]

[#2343]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/2343
[v2.5.4]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.5.3...v2.5.4

## [v2.5.3][v2.5.3]

### Released 2022-05-26

### Changed

- chore(deps): upgrade fluentd to 1.14.6-sumo-3 [#2287][#2287]

[v2.5.3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/compare/v2.5.2...v2.5.3

## [v2.5.2]

### Released 2022-02-17

### Changed

- chore: change Fluent Bit image to `public.ecr.aws/sumologic/fluent-bit:1.6.10-sumo-1`, it is Fluent Bit 1.6.10 with updated dependencies,
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

### Released 2022-05-26

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

### Released 2022-05-26

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
  - Update [Cascading Filter processor][v0.38.1-cfp] to a new version which adds new features such filtering by number of errors and
    switches to a new, [easier to use config format][v0.38.1-cfp-help]
  - Change the default number of traces for Cascading Filter to 200000

### Fixed

- Reduced the number of API server calls from the metrics metadata enrichment plugin by a significant amount [#1927][#1927]

[v2_3_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.3.0
[v0.38.1-cfp]:
  https://github.com/SumoLogic/opentelemetry-collector-contrib/tree/v0.38.1-sumo/processor/cascadingfilterprocessor#cascading-filter-processor
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

  Adds new `values.yaml` property `sumologic.logs.metadata.provider` and associated configuration properties to replace Fluentd with Sumo
  Logic Distro of OpenTelemetry Collector for logs metadata enrichment.

- otelcol: add systemd logs pipeline [#1767][#1767]

  - This change introduces logs metadata enrichment with Sumo Open Telemetry distro for systemd logs (when
    `sumologic.logs.metadata.provider` is set to `otelcol`)

    One notable change comparing the new behavior to `fluentd` metadata enrichment is that setting source name in `sourceprocessor`
    configuration is respected i.e. whatever is set in `otelcol.metadata.logs.config.processors.source/systemd.source_name` will be set as
    source name for systemd logs.

    The old behavior is being retained i.e. extracting the source name from `fluent.tag` using
    `attributes/extract_systemd_source_name_from_fluent_tag` processor. For instance, for `fluent.tag=host.docker.service`, source name will
    be set to `docker`.

    In order to set the source name to something else please change `otelcol.metadata.logs.config.processors.source/systemd:.source_name`
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
- fix: don't include fluentd.logs.containers.excludeNamespaceRegex in ns exclusion regex when collectionMonitoring is disabled
  [#1852][#1852]
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

## [v2.1.4][v2_1_4] - 2021-07-12

### Changed

- feat: add nginx plus to prometheus remote write (#1656) [#1685]

[v2_1_4]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.4
[#1685]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1685

## [v2.1.3][v2_1_3] - 2021-07-12

### Changed

- [Backport release-v2.1] fix: fix fluent-bit's imageSecrets comment [#1649]
- [Backport release-v2.1] chore: upgrade Tailing Sidecar Operator to v0.3.1 [#1682]

[v2_1_3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.3
[#1649]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1649
[#1682]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1682

## [v2.1.2][v2_1_2] - 2021-06-02

### Changed

- [Backport release-v2.1] fix documentation for gzip compression issue [#1594]
- Labeling statefulset pvcs (#1597) [#1602]
- [Backport release-v2.1] Add application_rules.yaml to falco.rulesFile [#1617]
- SUMO-165923 Updating the versions of kubernetes clusters (#1610) [#1619]
- [Backport release-v2.1] Fix additionalLabels in collection-fluent-bit [#1630]

[v2_1_2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.2
[#1594]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1594
[#1602]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1602
[#1617]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1617
[#1619]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1619
[#1630]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1630

## [v1.3.8][v1_3_8] - 2021-04-29

### Changed

- update terraform to 0.13.7 [#1592]

[v1_3_8]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.8
[#1592]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1592

## [v1.3.7][v1_3_7] - 2021-04-22

### Changed

- Specify 1.3 release when installing with helm [#1504]
- fix: Fix duplicated service names in metrics metadata [#1570]
- release: Prepare v1.3.7-rc.0 [#1575]
- release: Prepare v1.3.7 [#1584]

[v1_3_7]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.7
[#1504]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1504
[#1570]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1570
[#1575]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1575
[#1584]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1584

## [v2.1.1][v2_1_1] - 2021-04-19

### Changed

- fix: Remove Helm warning for tolerations [#1536]
- Upgrade metrics server subchart to 5.8.2 [#1538]
- chore: Upgrade Fluentd from 1.12.1-sumo-0 to 1.12.1-sumo-1 [#1539]
- Add troubleshooting section for the stuck PVCs [#1541]
- Add chart properties for per-container annotations [#1540]
- chore: Upgrade Fluent Bit and Metrics Server subcharts [#1543]
- chore: upgrade metrics server to 5.8.4 [#1545]
- [Backport release-v2.1] chore: Upgrade Fluentd from v1.12.1-sumo-2 to v1.12.2-sumo-0 [#1568]
- [Backport release-v2.1] Downgrade fluent-bit to 1.6.10 [#1564]

[v2_1_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.1
[#1536]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1536
[#1538]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1538
[#1539]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1539
[#1541]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1541
[#1540]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1540
[#1543]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1543
[#1545]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1545
[#1568]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1568
[#1564]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1564

## [v2.0.6][v2_0_6] - 2021-03-31

### Changed

- [Backport release-v2.0] Add troubleshooting section about not running Prometheus pod [#1517]
- [Backport release-v2.0] Check API errors when getting fields quota in setup job [#1525]
- [Backport release-v2.0] Use only 10 SHA characters for dev builds instead of 40 [#1527]

[v2_0_6]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.0.6
[#1517]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1517
[#1525]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1525
[#1527]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1527

## [v2.1.0][v2_1_0] - 2021-03-30

### Changed

- Bump fluentd image to 1.12.0 [#1351]
- Add gzip troubleshooting to v2 upgrade doc [#1350]
- Bump sumologic terraform provider to 2.6 and relax kubernetes provider version constraints [#1353]
- Add configuration for VS Code's Markdownlint extension [#1352]
- Add support for Falco on OpenShift 4.6 [#1354]
- Fix information about falco on GKE [#1360]
- Fix ECR image repository name after migration for agent [#1363]
- Use 40 SHA chars in dev helm chart versions [#1374]
- Bump setup job's main.tf to work with terraform 0.13 [#1385]
- Bump setup image to 2.0.1 [#1387]
- Add extensibility points in values.yaml for Fluentd plugins for logs [#1359]
- Bump fluentd from 1.12.0-sumo-0-rc.0 to 1.12.0-sumo-1-rc.0 [#1400]
- Upgrade fluent-bit to 1.6.10 [#1406]
- Switch to OTC v0.19.2-sumo [#1394]
- Enable otlphttp exporter in tracing collection [#1415]
- Upgrade Fluentd from 1.12.0-sumo-1.rc0 to rc.1 [#1427]
- Remove traces from Terraform docs mentioned twice [#1419]
- Upgrade otelagent version from 0.16.2-sumo to 0.19.2-sumo [#1430]
- Upgrade Fluentd to 1.12.0-sumo-1 [#1433]
- Add performance troubleshooting (fluent-bit mem buf limit) [#1428]
- Allow setting securityContext per container in fluentd statefulsets [#1439]
- Use the ECR repository for dependencies: Fluent Bit, Telegraf and Falco [#1442]
- The v2 migration script fix - migrate Fluent Bit image key instead of deleting it [#1444]
- Fix #1453, remove build-setup from Makefile and README [#1454]
- Add logs-keeper to vagrant [#1438]
- Change backport bot token [#1471]
- Make pdb definitions and usage consistent [#1469]
- Fix v2.0.0 migration script not migrating remoteTimeout [#1467]
- Backport bot use github app [#1476]
- Bump metrics-server to 5.5.0 [#1474]
- Refine requirements for sumologic-terraform-provider to ~> 2.8.0 [#1479]
- Bump setup image to 3.0.0 [#1481]
- Exclude `replicas` from Fluentd statefulsets when autoscaled [#1484]
- vagrant: add k9s to the Vagrant box [#1486]
- vagrant: add script to get kubeconfig for vagrant cluster [#1487]
- vagrant: get-kubeconfig: add verbose for moving old config [#1488]
- Upgrade Fluentd image to 1.12.0-sumo-2 [#1493]
- events: add overrideOutputConf property [#1497]
- Fix match fluent.\*\* deprecation warning [#1498]
- feat: Add source category prefix annotation [#1501]
- fluent-bit: disable keepalive [#1495]
- Add Tailing Sidecar Operator as Helm Chart dependency [#1507]
- Bump fluentd image to 1.12.0-sumo-4 [#1510]
- Bump fluentd image to v1.12.1-sumo-0-rc.1 [#1516]
- fix: Fix Fluentd image name [#1520]
- Check API errors when getting fields quota in setup job [#1524]
- Use only 10 SHA characters for dev builds instead of 40 [#1526]
- Upgrade subcharts [#1530]
- Upgrade subcharts [#1531]
- Bump OTC, add compression, use OTLPHTTP exporter [#1490]
- Upgrade Fluentd to 1.12.1-sumo-0 [#1533]

[v2_1_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.0
[#1351]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1351
[#1350]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1350
[#1353]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1353
[#1352]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1352
[#1354]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1354
[#1360]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1360
[#1363]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1363
[#1374]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1374
[#1385]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1385
[#1387]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1387
[#1359]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1359
[#1400]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1400
[#1406]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1406
[#1394]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1394
[#1415]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1415
[#1427]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1427
[#1419]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1419
[#1430]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1430
[#1433]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1433
[#1428]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1428
[#1439]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1439
[#1442]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1442
[#1444]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1444
[#1454]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1454
[#1438]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1438
[#1471]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1471
[#1469]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1469
[#1467]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1467
[#1476]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1476
[#1474]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1474
[#1479]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1479
[#1481]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1481
[#1484]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1484
[#1486]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1486
[#1487]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1487
[#1488]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1488
[#1493]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1493
[#1497]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1497
[#1498]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1498
[#1501]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1501
[#1495]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1495
[#1507]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1507
[#1510]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1510
[#1516]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1516
[#1520]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1520
[#1524]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1524
[#1526]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1526
[#1530]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1530
[#1531]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1531
[#1490]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1490
[#1533]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1533

## [v2.0.5][v2_0_5] - 2021-03-23

### Changed

- Upgrade Fluentd image to 1.12.0-sumo-2.1 [#1511]

[v2_0_5]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.0.5
[#1511]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1511

## [v2.0.4][v2_0_4] - 2021-03-19

### Changed

- [Backport release-v2.0] Change backport bot token [#1472]
- [Backport release-v2.0] Make pdb definitions and usage consistent [#1473]
- [Backport release-v2.0] Backport bot use github app [#1477]
- [Backport release-v2.0] Fix v2.0.0 migration script not migrating remoteTimeout [#1475]
- [Backport release-v2.0] Exclude `replicas` from Fluentd statefulsets when autoscaled [#1485]
- prepare-v2.0.4-rc.0 [#1489]
- [Backport release-v2.0] Upgrade Fluentd image to 1.12.0-sumo-2 [#1494]

[v2_0_4]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.0.4
[#1472]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1472
[#1473]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1473
[#1477]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1477
[#1475]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1475
[#1485]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1485
[#1489]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1489
[#1494]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1494

## [v2.0.3][v2_0_3] - 2021-02-23

### Changed

- [Backport release-v2.0] Allow setting securityContext per container in Fluentd statefulsets [#1443]
- [Backport release-v2.0] Use the ECR repository for dependencies: Fluent Bit, Telegraf and Falco [#1446]
- [Backport release-v2.0] The v2 migration script fix - migrate Fluent Bit image key instead of deleting it [#1447]
- [Backport release-v2.0] Fix #1453, remove build-setup from Makefile and README [#1455]

[v2_0_3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.0.3
[#1443]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1443
[#1446]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1446
[#1447]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1447
[#1455]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1455

## [v2.0.2][v2_0_2] - 2021-02-16

### Changed

- [Backport release-v2.0] Use 40 SHA chars in dev helm chart versions [#1377]
- Upgrade fluent-bit to 1.6.10 [#1405]
- [Backport release-v2.0] Add deprecation date to the v1.3 release [#1408]
- Switch to OTC v0.19.2-sumo [#1413]
- [Backport release-v2.0] Upgrade otelagent version from 0.16.2-sumo to 0.19.2-sumo [#1431]
- [Backport release-v2.0] Enable otlphttp exporter in tracing collection [#1425]
- Upgrade Fluentd to 1.12.0-sumo-1 [#1434]

[v2_0_2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.0.2
[#1377]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1377
[#1405]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1405
[#1408]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1408
[#1413]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1413
[#1431]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1431
[#1425]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1425
[#1434]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1434

## [v1.3.6][v1_3_6] - 2021-02-11

### Changed

- Add priorityClassName to events statefulset (#1006 backport) [#1009]
- Bump telegraf-operator to 1.1.6 (official 1.1.5 with helm2 support)(#1008 Backport) [#1010]
- add step for overriding node-exporter port in OpenShift [#990]
- Override Fluent Bit image to 1.6.0 for Helm chart version 1.3 [#1019]
- Otc v0.12 on v1.3 [#1013]
- Use new Helm stable repo URL for Fluent Bit [#1079]
- Use new Helm stable repo URL for metrics-server [#1081]
- Add OTLP HTTP port to the OpenTelemetry Collector [#1088]
- Adds Kubernetes App update info after successful migration (backport of #856) [#1098]
- Fix for chart documentation spelling of Fluent Bit and Kube Prometheus Stack [#1144]
- Add tracing to the helm chart description (backport of #1153) [#1154]
- Drop kubelet/systemd logs if they are disabled [#1166]
- Migrate off of the Docker Hub images into GitHub packages [#1168]
- Add pushing images to ghcr.io for release builds [#1217]
- Add travis for overrides [#1221]
- Replace ghcr.io with public AWS ECR [#1223]
- Backport Bundle kubernetes_metadata plugin with fix for Fluentd pod restarts [#1193]
- Use sumologic alias for ECR [#1241]
- Bump Helm 2 from 2.16.11 to 2.17.0 in CI [#1262]
- Prevent access to uninitialized variable [#1261]
- Add changes required for OpenShift support [#1267]
- Use minimal scc permissions [#1272]
- Do not attach empty 'node' metadata [#1268]
- Add ECR push to 1.3 branch [#1275]
- Upgrade Falco dependency to 1.5.7 [#1278]
- Upgrade Fluentd from 1.11.1 to 1.11.5 [#1284]
- Fix upgrade-script for logs migrations for v1.0 [#1296]
- Add prom oper compatibility note to docs [#1321]
- Update supported k8s versions for the v1.3: add AKS and EKS 1.18, rem… [#1324]
- Upgrade the subcharts versions [#1331]
- Fix #1322, update information about changing Fluentd persistence [#1330]
- Add OpenShift 3.11 support info [#1366]
- [Backport of #1354] Add support for falco on OpenShift with missing kernel-devel package [#1369]
- Upgrade terraform sumologic provider in release v1.3 [#1378]
- Use 40 SHA chars in dev helm chart versions on release-1.3 branch [#1376]
- [Backport] Fix information about falco on GKE [#1386]
- Make connections to k8s API server persistent [#1390]
- Bump fluent-bit to 1.6.10 [#1404]
- Add deprecation date to the v1.3 release [#1409]

[v1_3_6]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.6
[#1296]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1296
[#1321]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1321
[#1324]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1324
[#1331]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1331
[#1330]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1330
[#1366]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1366
[#1369]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1369
[#1378]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1378
[#1376]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1376
[#1386]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1386
[#1390]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1390
[#1404]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1404
[#1409]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1409

## [v2.0.1][v2_0_1] - 2021-01-22

### Changed

- Add new prometheus CRDs to vagrant makefile when removing them from cluster [#1335]
- Pin setup image to alpine:3.12 [#1339]
- Fix fluent-bit extraVolumes and extraVolumeMounts migration for v2 [#1342]
- [Backport release-v2.0] Bump kubernetes-tools to 2.3.1 in v2 migration doc [#1347]
- [Backport release-v2.0] Add gzip troubleshooting to v2 upgrade doc [#1357]
- [Backport release-v2.0] Add support for falco on OpenShift 4.6 [#1358]
- [Backport release-v2.0] Fix ECR image repository name after migration for agent [#1364]
- Don't build setup image [#1367]

[v2_0_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.0.1
[#1335]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1335
[#1339]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1339
[#1342]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1342
[#1347]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1347
[#1357]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1357
[#1358]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1358
[#1364]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1364
[#1367]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1367

## [v2.0.0][v2_0_0] - 2021-01-14

### Changed

- Add check for vagrant disksize plugin in Vagrantfile [#996]
- Allow HostsPorts for openshift (required for node-exporter) [#997]
- Extract unit tests from build.sh and run as separate build stage [#974]
- Upgrade fluent-plugin-kubernetes_metadata_filter from 2.4.1 to 2.5.2 [#998]
- Add known k8s api callers to vagrant values.yaml and upgrade falco chart to 1.5.0 [#1003]
- exclude fluentd warning message [#1004]
- Add priorityClassName to events statefulset [#1006]
- Bump fluentd and enable gzip compression by default [#1001]
- Bump telegraf-operator to 1.1.6 (official 1.1.5 + helm2 support) [#1008]
- Add information how to setup metrics-server in kops clusters [#1011]
- Bump sumologic-terraform-provider to 2.3.3 [#1018]
- move metrics server chart repo [#890]
- Fix vagrant values.yaml and add limits for prometheus [#1024]
- fix typo in helm installation command [#1028]
- Add custom terraform and bash script to the setup [#1020]
- Add possibility to disable metrics coming from OTC [#994]
- Always create custom setup configmap [#1032]
- Add jq and kubelet webhook authorization to vagrant [#1026]
- Add perf test script using avalanche [#1025]
- Override Fluent Bit image to fluent/fluent-bit:1.6.0 [#1017]
- Change default Fluent Bit config: use Docker_Mode [#1035]
- Bump Vagrant VM to Ubuntu 20.04 [#1031]
- Enable FluentD file persistence by default [#1033]
- Upgrade OpenTelemetry Collector to v0.12 [#1012]
- Rename OTC setting metrics_enabled into metrics.enabled [#1037]
- Add persistentVolumeClaim to scc [#1039]
- Add condition when creating metrics pdb [#1047]
- Add metrics pdb template [#1048]
- Add extraEnvVars to the otelcol [#1050]
- Add extraVolumeMounts and extraVolumes to the otelcol [#1051]
- Add cleanup to travis [#1056]
- Update falco rules in vagrant [#1058]
- Add checksum/config annotations for fluentd and otelcol [#1053]
- Use helm from kubernetes-tools [#1054]
- Add falco rules based on images [#1059]
- Drop helm2 support [#1060]
- Enable compression in fluentd output plugin by default [#1062]
- Add curl and jq to docker image [#1065]
- Bump terraform providers [#1070]
- Create fields automatically in setup job [#1064]
- Check if docker daemon is running before running tests [#1075]
- Add fluentd.metrics.overrideOutputConf [#1057]
- Remove overrides files, stop generating them and remove kubernetes directory [#1052]
- Use new stable repo URL in [#1073]
- Remove files (fixup #1052 rebase) [#1078]
- Set Prometheus data retention to 1 day (#793) [#1083]
- Add OTLP HTTP port [#1086]
- Bump sumologic/kubernetes-tools to 2.0.0 [#1087]
- Update autoscaling/v1 to autoscaling/v2beta2 [#1071]
- Adds Kubernetes App update info after successful migration [#856]
- Add clean up job to delete collector when collection is uninstalled [#1092]
- Allow specifying pullSecrets [#1104]
- Upgrade Prometheus chart to 12.0.2 and rename prometheus-operator to kube-prometheus-stack [#1089]
- Migrate to new Fluent Bit helm chart [#1102]
- Update Falco to 1.5.4 [#1115]
- Add forwarding kubelet_running containers and pods metrics [#1118]
- Push dev charts into dev directory [#1122]
- Add missing space in helm merge command [#1125]
- Switch back to docker_mode [#1133]
- Only import sources when collector exists [#1137]
- Bump metrics-server to 5.0.2 [#1140]
- v2 migration script [#1121]
- Bundle terraform providers in kubernetes-fluentd image [#1145]
- Drop kubelet/systemd logs if they are disabled [#1128]
- Migrate image to fluentd.image and sumologic.setup.job.image [#1148]
- Migrate otelcol image name to otelcol image repository [#1149]
- Fix fluentd systemd logs dropping (typo) [#1150]
- Add tracing to the helm chart description [#1153]
- Use official repo for telegraf-operator [#1147]
- Bump chart API version to v2 [#1159]
- Add targets to test logs and metrics from receiver-mock [#1162]
- reword: docker registry -> container registry [#1161]
- Clean up collector keys in values.yaml [#1160]
- Bundle kubernetes_metadata plugin with fix for Fluentd pod restarts [#1183]
- Update issue templates - bug report [#1163]
- Update issue template for feature request [#1164]
- Update issue templates - question [#1165]
- Clean makefile and update vagrant due to new ruby package [#1184]
- Change ServiceMonitor for fluent-bit - port and matchLabels [#1188]
- Fix expose-prometheus target in Makefile [#1189]
- Improve vagrant's Makefile [#1194]
- Migrate off of the legacy pre-1.14 recording rules [#1030]
- Add a new label for scraping metrics [#1190]
- Add v2 migrations steps [#1172]
- OpenTelemetry Agent support [#1027]
- Set prometheus remoteTimeout to 5s [#1199]
- Update coredns metrics due to 1.7.0 release [#1200]
- Bump fluentd image to v1.11.5 [#1204]
- Bump receiver-mock image in vagrant to kubernetes-tools:2.1.0 [#1205]
- Upgrade Kube Prometheus Stack to 12.3.0 [#1207]
- Upgrade Fluent Bit to 0.7.10 and Falco to 1.5.5 [#1206]
- Prevent "undefined local variable or method" error from enhance_k8s_metadata Fluent plugin [#1212]
- Update scheduler metrics [#1219]
- Upgrade script v2 - fluentd.persistence migration [#1213]
- Remove unused Travis config and badge [#1215]
- kubernetes-setup Dockerfile [#1226]
- Upgrade Fluent Bit to 0.7.13 [#1230]
- Move from Docker Hub to ECR Public [#1232]
- Use separate setup job image in Vagrant [#1235]
- Remove leftovers from building Fluentd image [#1236]
- Use sumologic alias for ECR [#1237]
- Upgrade Kube Prometheus Stack to 12.8.0 and Falco to 1.5.6 [#1238]
- Upgrade v2 script prometheus migration [#1216]
- Check minimal k8s version before installation [#1240]
- Upgrade Falco to 1.5.7 [#1246]
- Explicitly log that setup.sh is missing when using custom setup scripts [#1247]
- Migration script v2 set remoteWrite remoteTimeout to 5s [#1243]
- Don't install aws cli when already available in gh env with ecr-public command [#1254]
- Bump kubernetes-tools to 2.2.0 [#1257]
- Add migration logic to v2 upgrade script for prometheus remote write regexes [#1256]
- Don't support yq version 4.0 and above in migration script v2 [#1260]
- Update sumologic/kubernetes-fluentd image to 2.0.0-beta.1 [#1270]
- Remove fluent-bit rawConfig mentions after upgrading to new fluent-bit chart [#1264]
- Add steps required for fluent-bit to upgrade [#1242]
- Use minimal scc permissions [#1274]
- Upgrade Kube Prometheus Stack to 12.8.1 [#1269]
- Fix upgrade v2 script image rename [#1277]
- Upgrade v2 script - metrics server [#1282]
- Upgrade Fluentd image to 1.11.5-sumo-0 [#1286]
- Upgrade Sumologic Kubernetes Tool version to 2.2.3 [#1283]
- Extract FLUENTD_METRICS_SVC from the CHART variable [#1288]
- Upgrade Kube Prometheus Stack to 12.10.6 [#1291]
- Add output yaml flag to helm get values [#1292]
- Fix upgrade-script for logs migrations for v1.0 [#1297]
- Add v2 migration logic for fluent-bit section [#1299]
- Upgrade OTC to 0.16.0-sumo [#1259]
- Use RELEASE-NAME placeholder in upgrade command [#1298]
- Migrate prometheus pre 1.14 rules only when prometheus-operator.kubeTargetVersionOverride is set to 1.13.0-0 [#1301]
- Migrate prometheus-config-reloader only when overwritten in values.yaml [#1302]
- Add v2 migration for fluent bit configs [#1304]
- Add v2 migration logic for prometheus retention [#1303]
- Rename CHART variable into FLUENTD_LOGS_SVC [#1289]
- Add information about warning when resource managed by helm is modified [#1300]
- Add missing node:node_memory_bytes_available:sum prometheus recording rule [#1306]
- Bump kube-prometheus-stack to 12.11.3 [#1307]
- Bump OTC to 0.16.2-sumo [#1311]
- Update v2 migration script logs [#1308]
- Update prometheus CRDs update instructions for 2.0 migration [#1310]
- kube-scheduler and kube-controller-manager listen on all interfaces in vagrant [#1312]
- Add if conditions to fluentd configuration templates [#1314]
- Update v2 migration script - quote empty values [#1315]
- v2 migration script - change wording when unexpected fluent-bit section encountered [#1317]
- Don't add empty lines to Fluent-bit config [#1318]
- Add migration instruction for non-helm users [#1309]
- Add note on upgrading external Prometheus operator [#1316]
- Update information about changing Fluentd persistence [#1294]
- v2 migration script - add fluent bit multiline migration [#1325]
- Update v2 migration docs with migration script in container usage [#1326]
- Downgrade Kube Prometheus Stack to 12.3.0 and 0.43.2 CRD version for be… [#1329]
- Rename cleanUpEnabled to cleanupEnabled [#1336]
- Fix secret cleanup [#1337]

[v2_0_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.0.0
[#996]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/996
[#997]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/997
[#974]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/974
[#998]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/998
[#1003]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1003
[#1004]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1004
[#1006]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1006
[#1001]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1001
[#1008]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1008
[#1011]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1011
[#1018]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1018
[#890]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/890
[#1024]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1024
[#1028]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1028
[#1020]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1020
[#994]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/994
[#1032]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1032
[#1026]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1026
[#1025]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1025
[#1017]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1017
[#1035]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1035
[#1031]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1031
[#1033]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1033
[#1012]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1012
[#1037]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1037
[#1039]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1039
[#1047]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1047
[#1048]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1048
[#1050]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1050
[#1051]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1051
[#1056]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1056
[#1058]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1058
[#1053]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1053
[#1054]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1054
[#1059]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1059
[#1060]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1060
[#1062]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1062
[#1065]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1065
[#1070]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1070
[#1064]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1064
[#1075]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1075
[#1057]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1057
[#1052]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1052
[#1073]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1073
[#1078]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1078
[#1083]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1083
[#1086]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1086
[#1087]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1087
[#1071]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1071
[#856]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/856
[#1092]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1092
[#1104]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1104
[#1089]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1089
[#1102]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1102
[#1115]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1115
[#1118]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1118
[#1122]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1122
[#1125]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1125
[#1133]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1133
[#1137]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1137
[#1140]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1140
[#1121]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1121
[#1145]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1145
[#1128]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1128
[#1148]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1148
[#1149]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1149
[#1150]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1150
[#1153]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1153
[#1147]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1147
[#1159]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1159
[#1162]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1162
[#1161]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1161
[#1160]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1160
[#1183]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1183
[#1163]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1163
[#1164]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1164
[#1165]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1165
[#1184]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1184
[#1188]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1188
[#1189]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1189
[#1194]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1194
[#1030]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1030
[#1190]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1190
[#1172]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1172
[#1027]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1027
[#1199]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1199
[#1200]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1200
[#1204]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1204
[#1205]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1205
[#1207]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1207
[#1206]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1206
[#1212]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1212
[#1219]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1219
[#1213]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1213
[#1215]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1215
[#1226]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1226
[#1230]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1230
[#1232]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1232
[#1235]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1235
[#1236]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1236
[#1237]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1237
[#1238]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1238
[#1216]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1216
[#1240]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1240
[#1246]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1246
[#1247]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1247
[#1243]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1243
[#1254]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1254
[#1257]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1257
[#1256]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1256
[#1260]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1260
[#1270]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1270
[#1264]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1264
[#1242]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1242
[#1274]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1274
[#1269]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1269
[#1277]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1277
[#1282]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1282
[#1286]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1286
[#1283]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1283
[#1288]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1288
[#1291]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1291
[#1292]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1292
[#1297]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1297
[#1299]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1299
[#1259]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1259
[#1298]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1298
[#1301]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1301
[#1302]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1302
[#1304]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1304
[#1303]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1303
[#1289]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1289
[#1300]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1300
[#1306]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1306
[#1307]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1307
[#1311]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1311
[#1308]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1308
[#1310]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1310
[#1312]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1312
[#1314]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1314
[#1315]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1315
[#1317]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1317
[#1318]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1318
[#1309]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1309
[#1316]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1316
[#1294]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1294
[#1325]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1325
[#1326]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1326
[#1329]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1329
[#1336]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1336
[#1337]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1337

## [v1.3.5][v1_3_5] - 2020-12-30

### Changed

- Prevent access to uninitialized variable [#1261]
- Add changes required for OpenShift support [#1267]
- Use minimal scc permissions [#1272]
- Do not attach empty 'node' metadata [#1268]
- Add ECR push to 1.3 branch [#1275]
- Upgrade Falco dependency to 1.5.7 [#1278]

[v1_3_5]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.5
[#1261]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1261
[#1267]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1267
[#1272]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1272
[#1268]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1268
[#1275]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1275
[#1278]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1278

## [v1.3.4][v1_3_4] - 2020-12-16

### Changed

- Backport Bundle kubernetes_metadata plugin with fix for Fluentd pod restarts [#1193]
- Use sumologic alias for ECR [#1241]

[v1_3_4]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.4
[#1193]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1193
[#1241]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1241

## [v1.3.3][v1_3_3] - 2020-12-04

### Changed

- Adds Kubernetes App update info after successful migration (backport of #856) [#1098]
- Add tracing to the helm chart description (backport of #1153) [#1154]
- Drop kubelet/systemd logs if they are disabled [#1166]
- Migrate off of the Docker Hub images into GitHub packages [#1168]
- Add travis for overrides [#1221]
- Replace ghcr.io with public AWS ECR [#1223]

[v1_3_3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.3
[#1098]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1098
[#1144]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1144
[#1154]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1154
[#1166]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1166
[#1168]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1168
[#1217]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1217
[#1221]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1221
[#1223]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1223

## [v1.3.2][v1_3_2] - 2020-11-12

### Changed

- Use new Helm stable repo URL for Fluent Bit [#1079]
- Use new Helm stable repo URL for metrics-server [#1081]
- Add OTLP HTTP port to the OpenTelemetry Collector [#1088]

[v1_3_2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.2
[#1079]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1079
[#1081]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1081
[#1088]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1088

## [v1.3.1][v1_3_1] - 2020-10-27

### Changed

- Remove unsupported AKS 1.15 and GKE 1.14 from the docs [#984]
- Add tracing and OpenTelemetry to the overview image on the repo home page [#988]
- Fix: do not change timestamps for already existing helm charts [#992]
- Add priorityClassName to events statefulset (#1006 backport) [#1009]
- Bump telegraf-operator to 1.1.6 (official 1.1.5 with helm2 support)(#1008 Backport) [#1010]
- Override Fluent Bit image to 1.6.0 for Helm chart version 1.3 [#1019]
- Otc v0.12 on v1.3 [#1013]

[v1_3_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.1
[#984]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/984
[#988]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/988
[#992]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/992
[#1009]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1009
[#1010]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1010
[#990]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/990
[#1019]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1019
[#1013]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1013

## [v1.3.0][v1_3_0] - 2020-10-06

### Changed

- Don't scrape from headless services [#895]
- attach node metadata to metrics when not present [#854]
- add pdb for fluentd logs and metrics [#781]
- add nodeSelector for setup job [#783]
- add container_cpu_cfs_throttled_seconds_total metric [#886]
- capture hpa metrics [#884]
- Add priority class to fluentd sts [#784]
- Don't mount and don't define pos volumes for fluentd [#903]
- Scrap metrics from pods basing on annotations [#852]
- define resources for thanos sidecar [#874]
- Update Falco helm chart to 1.3.0 [#909]
- add source category for default logs pipeline [#780]
- change prometheus-operator repo [#908]
- add alias for kube-prometheus-stack helm chart [#910]
- Support all securityContext resources [#889]
- Add build target to the vagrant's Makefile [#913]
- Add HTTP protocol for OTLP receiver [#915]
- Rename sumologic to sumo-make and add bash completion [#902]
- Add telegraf operator helm chart to the requirements [#893]
- Fix grafana installation in vagrant [#922]
- Do not proxy kubernetes internal traffic [#920]
- Fix kubeclient v4.9.1 usage with group apis [#927]
- Add nginx to the vagrant environment [#924]
- Point to correction section in Fields doc for pre-req step [#930]
- support openshift [#925]
- add resource limits to setup job pod [#782]
- Increase cache refresh interval to 1 hour [#912]
- Increase memory limits for thanos-sidecar to 32Mi to prevent restarts [#936]
- Fix handling api versions in fluent-plugin-enhance-k8s-metadata [#942]
- Add shellcheck to vagrant [#943]
- Openshift docs [#937]
- add psp templates to the helm chart [#933]
- Install shellcheck with apt in vagrant [#945]
- Add redis to the vagrant environment [#921]
- Extract bundle fluentd plugins function [#946]
- refactor: local variables in bundle_fluentd_plugins function in ci/bu… [#947]
- Increase Vagrant disk size from 10 GB to 50 GB [#948]
- Improve vagrant tests [#944]
- Refactor build Dockerfile [#949]
- Add jmx application to the vagrant [#926]
- Forward redis metrics to the sumologic [#951]
- add crio parser to fluent-bit [#950]
- change prometheus-operator docs to kube-prometheus-stack [#939]
- Introduce cache refresh variation [#952]
- Fix tmp file path in tests [#957]
- Bump requirements versions: Fluent Bit, Prometheus, Falco, Metrics Se… [#958]
- update dependent helm chart matrix [#955]
- Use local changes when building and running locally [#953]
- Add list of jmx metrics [#954]
- add resource limits for prometheus container [#959]
- Extract script for getting the dashboard token [#962]
- refactor: use custom template names for scc and psp metadata and labels [#963]
- rename hpa metrics [#965]
- change cpu limits format [#966]
- Include OpenTelemetry Collector logs by default [#960]
- revert prom-operator version bump [#969]
- Update info about adoptopenjdk-openj9 missing metrics [#970]
- Cleanup white chars from v1.2.0 [#972]
- fix: remove adding new resources limits and requests from 1.3 [#971]
- Revert to using helm stable for Prometheus Operator chart [#975]
- Revert the FluentD image version to 1.2.3 [#976]
- Revert "Revert the FluentD image version to 1.2.3" [#977]
- add back all resource limits and turn off kubelet resource scraping [#978]
- Revert "Revert to using helm stable for Prometheus Operator chart" [#979]
- prep v1.3.0-beta2 [#980]
- Add flags related to Telegraf Operator to the chart's README [#983]
- Include description of otelcol Helm chart params [#981]

[v1_3_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.3.0
[#895]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/895
[#854]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/854
[#781]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/781
[#783]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/783
[#886]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/886
[#884]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/884
[#784]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/784
[#903]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/903
[#852]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/852
[#874]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/874
[#909]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/909
[#780]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/780
[#908]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/908
[#910]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/910
[#889]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/889
[#913]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/913
[#915]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/915
[#902]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/902
[#893]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/893
[#922]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/922
[#920]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/920
[#927]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/927
[#924]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/924
[#930]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/930
[#925]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/925
[#782]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/782
[#912]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/912
[#936]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/936
[#942]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/942
[#943]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/943
[#937]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/937
[#933]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/933
[#945]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/945
[#921]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/921
[#946]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/946
[#947]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/947
[#948]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/948
[#944]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/944
[#949]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/949
[#926]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/926
[#951]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/951
[#950]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/950
[#939]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/939
[#952]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/952
[#957]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/957
[#958]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/958
[#955]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/955
[#953]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/953
[#954]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/954
[#959]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/959
[#962]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/962
[#963]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/963
[#965]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/965
[#966]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/966
[#960]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/960
[#969]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/969
[#970]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/970
[#972]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/972
[#971]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/971
[#975]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/975
[#976]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/976
[#977]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/977
[#978]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/978
[#979]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/979
[#980]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/980
[#983]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/983
[#981]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/981

## [v1.2.3][v1_2_3] - 2020-09-21

### Changed

- Backport #920 - do not proxy kubernetes internal traffic [#928]

[v1_2_3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.2.3
[#928]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/928

## [v1.2.2][v1_2_2] - 2020-09-11

### Changed

- Provide FluentD file persistence setting key in the chart notes [#876]
- Add steps for disabling logs, metrics, or falco [#875]
- Drop container=pod label when scraping container network metrics [#879]
- Relabel pod and service dimensions for non-pod metrics [#878]
- Retry creating kubeclients in FluentD when error [#855]
- Fix prometheus configuration [#883]
- Add troubleshooting section in Vagrant README [#888]

[v1_2_2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.2.2
[#876]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/876
[#875]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/875
[#879]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/879
[#878]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/878
[#855]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/855
[#883]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/883
[#888]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/888

## [v1.2.1][v1_2_1] - 2020-08-31

### Changed

- Use fixed kubeclient version 4.9.0 for fluent-plugin-enhance-k8s-meta… [#870]
- Revert removal of traces config [#868]

[v1_2_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.2.1
[#870]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/870
[#868]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/868

## [v1.2.0][v1_2_0] - 2020-08-28

### Changed

- Updates to fluentd base image [#817]
- Enable file persistence by default [#816]
- Use Otelcol 0.6.1 and corresponding configuration [#808]
- add custom labels to fluentd sts and setup job pods [#819]
- Fixing a typo in additional Prometheus configuration [#792]
- Add customLabels for kube-state-metrics [#824]
- Allow custom pod annotations in helm chart [#822]
- prepare v.1.2.0-beta.0 [#828]
- expose extra conf for fluentd in_forward [#832]
- fix podLabels [#838]
- update autoscaling section in docs [#839]
- Add makefile to vagrant to install collection, receiver-mock, grafana and supports avalanche [#815]
- Fix incorrectly indented podAnnotations [#843]
- Fixing the indentation of the processing rule example [#835]
- Unify comments in values.yaml - make them start with two hash characters [#836]
- Last fixes for values.yaml [#844]
- Fix broken setup job helm.sh annotations [#847]
- Clarify docs for custom logs conf [#842]
- Allow custom pod annotations for kube-state and prometheus [#848]
- Set text compress as default option for FluentD file buffer [#850]
- Use variables in documentation for additional prometheus metrics [#851]
- disable fluentd persistence by default [#858]
- Update helm chart configuration doc with podLabels and podAnnotations changes [#857]
- Bump documentation version to 1.2 [#864]

[v1_2_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.2.0
[#817]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/817
[#816]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/816
[#808]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/808
[#819]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/819
[#792]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/792
[#824]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/824
[#822]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/822
[#828]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/828
[#832]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/832
[#838]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/838
[#839]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/839
[#815]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/815
[#843]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/843
[#835]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/835
[#836]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/836
[#844]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/844
[#847]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/847
[#842]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/842
[#848]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/848
[#850]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/850
[#851]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/851
[#858]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/858
[#857]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/857
[#864]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/864

## [v1.1.0][v1_1_0] - 2020-07-30

### Changed

- ingest retry succeeded logs and expose param in values file [#671]
- Update falco helm chart [#670]
- Update fluent-bit helm chart [#669]
- Update metrics server helm chart [#668]
- Update prometheus operator helm chart [#667]
- Add dynamic generation of terraform kubernetes object [#675]
- List metrics forwarded to the sumologic [#629]
- Set `Ignore_Older` to `24h` by default to prevent older logs from being ingested on install. [#664]
- Expose Scrape Intervals in values.yaml to make it easier to adjust. [#665]
- Ensure clusterName has no spaces to prevent issue with Explore rendering. [#679]
- Generate labels and names using helm templates [#685]
- add collectionMonitoring logic [#682]
- expose extraEnvVars, extraVolumes, extraVolumeMounts [#681]
- Use env for prometheus metrics namespace [#690]
- Fix labels for headless services [#689]
- Switch helm chart from helm/stable to falcosecurity/charts. [#695]
- Support installation behind proxy [#692]
- optional metrics resources [#683]
- Expose http sources for metrics in values.yaml [#672]
- Change default retry_timeout to 1h [#700]
- Filter list of control-plane app metrics [#697]
- Fix Travis build due to default shallow git clone [#702]
- Fix terraform import and additional fields [#704]
- Handle Collector name with spaces [#706]
- fix indentation [#707]
- expose the k8s api version and groups as params [#565]
- Dynamic generation of terraform properties [#705]
- Fix terraform tests [#716]
- add db for systemd [#713]
- Bump terraform providers [#714]
- Otelcol config update with batch size and source processor [#715]
- Add generator for logs, events and traces sources [#708]
- enable wal compression by default [#719]
- Add missing metrics to fluentd [#718]
- Split sumo-k8s.tf on multiple terraform files [#721]
- Fix potential tf race confition [#722]
- set correct source host for systemd logs [#725]
- Fix helm chart requirements conditions [#731]
- Use sumologic.com as prefix for internal labels [#734]
- Remove unused grafana.enabled key [#739]
- Bump k8s in vagrant to 1.18 [#743]
- increase fluentd evets sts resource limits [#744]
- Severity1 fix 741 [#745]
- Add extra volumes for events [#756]
- Fix indents on FluentDs extraEnvVars and extraVolumes [#757]
- Fill cluster name property for traces [#754]
- Vagrant box update: use newest helm 2 and 3 versions and drop the mic… [#760]
- fix: HPA for FluentDs [#763]
- update non-helm migration steps to only what is needed [#767]
- Bump supported k8s versions [#737]
- Use retry_max_interval instead of retry_timeout for fluentd buffer [#768]
- Use SUMO_ENDPOINT_DEFAULT_TRACES_SOURCE env [#778]
- Add information about building the endpoint variable names [#771]
- Update ref to falco in values.yaml [#777]
- Bump supported AKS versions [#794]
- Remove the unused sumologic.traces.endpoint key (clean up otelcol conf after the #778 merge) [#779]
- Metrics fix: replace the scheduler_binding_latency_microseconds with … [#795]
- Update values.yaml [#799]
- Update values.yaml [#804]

[v1_1_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.1.0
[#671]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/671
[#670]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/670
[#669]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/669
[#668]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/668
[#667]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/667
[#675]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/675
[#629]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/629
[#664]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/664
[#665]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/665
[#679]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/679
[#685]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/685
[#682]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/682
[#681]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/681
[#690]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/690
[#689]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/689
[#695]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/695
[#692]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/692
[#683]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/683
[#672]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/672
[#700]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/700
[#697]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/697
[#702]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/702
[#704]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/704
[#706]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/706
[#707]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/707
[#565]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/565
[#705]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/705
[#716]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/716
[#713]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/713
[#714]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/714
[#715]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/715
[#708]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/708
[#719]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/719
[#718]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/718
[#721]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/721
[#722]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/722
[#725]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/725
[#731]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/731
[#734]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/734
[#739]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/739
[#743]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/743
[#744]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/744
[#745]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/745
[#756]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/756
[#757]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/757
[#754]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/754
[#760]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/760
[#763]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/763
[#767]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/767
[#737]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/737
[#768]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/768
[#778]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/778
[#771]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/771
[#777]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/777
[#794]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/794
[#779]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/779
[#795]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/795
[#799]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/799
[#804]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/804

## [v1.0.0][v1_0_0] - 2020-05-21

### Changed

- Revert "revert all 1.0.0 changes" [#509]
- Removed references to out of date helm chart versions which are no lo… [#512]
- disable falco by default [#465]
- [1.0.0] change default DB path for fluentbit [#450]
- [1.0.0] filter metrics [#466]
- [1.0.0] add fluentd to name of both logs and events fluentd statefulsets [#454]
- add sed command to replace cluster name for non-helm users [#517]
- Added how to modify the log level for Falco [#522]
- Add vagrant configuration for testing purposes [#418]
- Add helm RBAC error and solution [#527]
- Added another example for filtering metrics [#529]
- Reformatted CLI examples to more easily readable [#534]
- Remove reference to setting cluster in Prometheus [#538]
- Allow to install plugins in docker image [#542]
- Explain confusing Terraform Errors [#537]
- add steps for additional buffer & flush parameters [#533]
- add quotes when specifying events sourceCategory [#549]
- Set namepace and cluster name when deploying fluentd [#553]
- [1.0.0] Upgrade script to convert values.yaml to 1.0.0 [#555]
- Add fluentd to service name to fix urls [#548]
- [1.0.0] expose override raw conf for container log pipeline [#556]
- add plugin specific log level for metadata and output plugins [#559]
- remove sourceHost from values.yaml [#546]
- Update OtelCol and clean up tags [#560]
- vagrant: Bump k8s to 1.15 [#563]
- Fix buffers according to 1.0.0 [#568]
- Bump Falco chart to 1.1.6 [#567]
- Fix HPA for fluentd after changing it into statefulset [#576]
- Add Zipkin write port to the Fluentd's headless service [#575]
- Adjust fluentd names and app labels [#573]
- Add note on how to handle Prometheus replicas. [#579]
- Fix filtering metrics for old kubernetes versions [#586]
- expose fluentd output section for logs [#585]
- K8S diagnostics image with debugging tools [#584]
- Expose resource config for prometheus node-exporter and kube state metrics. [#593]
- Include serviceaccount in the usage description [#590]
- Small fixes due to 0.17 to 1.0 upgrade testing [#592]
- Bump sumologic fluentd output plugin and override sumo_client with helm version [#597]
- split logs + metrics Fluentd sts [#588]
- Do not pass histogram metrics to the fluentd [#595]
- Fix fluentd url for tracing [#604]
- Upgrade script fixes [#613]
- Trace stress-testing generator [#606]
- Use Otelcol v0.3 and send spans directly [#611]
- 1.0.0 upgrade script upgrade [#617]
- Adjust events naming to the new fluentd- schema [#615]
- Fix the unbound variable 1 error in the upgrade script [#624]
- Update previous version in upgrade script [#628]
- v1 fluentd config examples [#625]
- Re-cast to string for particular keys [#635]
- Provide default, commented out limits and resources for Prometheus - … [#637]
- Fixes for 1.0 upgrade [#641]
- Add --force flag for pv [#649]
- remove -o flag [#651]
- Upgrade script grep sed bash fixes [#647]
- add baseImage for thanos [#650]
- Replace grep in favor of sed for upgrade script tests [#654]
- Remove tools [#658]
- [fix] FluentD's overrideOuputConf needs some indenting [#659]

[v1_0_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v1.0.0
[#509]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/509
[#512]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/512
[#465]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/465
[#450]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/450
[#466]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/466
[#454]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/454
[#517]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/517
[#522]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/522
[#418]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/418
[#527]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/527
[#529]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/529
[#534]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/534
[#538]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/538
[#542]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/542
[#537]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/537
[#533]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/533
[#549]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/549
[#553]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/553
[#555]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/555
[#548]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/548
[#556]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/556
[#559]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/559
[#546]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/546
[#560]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/560
[#563]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/563
[#568]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/568
[#567]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/567
[#576]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/576
[#575]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/575
[#573]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/573
[#579]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/579
[#586]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/586
[#585]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/585
[#584]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/584
[#593]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/593
[#590]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/590
[#592]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/592
[#597]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/597
[#588]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/588
[#595]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/595
[#604]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/604
[#613]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/613
[#606]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/606
[#611]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/611
[#617]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/617
[#615]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/615
[#624]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/624
[#628]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/628
[#625]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/625
[#635]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/635
[#637]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/637
[#641]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/641
[#649]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/649
[#651]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/651
[#647]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/647
[#650]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/650
[#654]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/654
[#658]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/658
[#659]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/659

## [v0.17.4][v0_17_4] - 2020-05-20

### Changed

- add baseImage for thanos [#655]

[v0_17_4]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.17.4
[#655]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/655

## [v0.17.3][v0_17_3] - 2020-05-13

### Changed

- Backport 'add quotes when specifying events sourceCategory' (#549) [#619]

[v0_17_3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.17.3
[#619]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/619

## [v0.17.2][v0_17_2] - 2020-05-06

### Changed

- Allow dev builds on release branches [#544]
- change tag to release branch [#551]
- Added endpoint into helm CLI until the bug fix [#564]
- Clean up tag names [#562]
- Use Otelcol v0.3 and send spans directly [#600]

[v0_17_2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.17.2
[#544]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/544
[#551]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/551
[#564]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/564
[#562]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/562
[#600]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/600

## [v0.17.1][v0_17_1] - 2020-03-31

### Changed

- Include otelcol metrics [#503]
- Bump otelcol to newer version [#510]
- Release v0.17 backports [#515]
- add sed command to replace cluster name for non-helm users [#524]
- Hostname and \_sourceHost fix for v0.17 [#530]
- Revert the \_sourceHost changes [#535]

[v0_17_1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.17.1
[#503]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/503
[#510]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/510
[#515]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/515
[#524]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/524
[#530]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/530
[#535]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/535

## [v0.17.0][v0_17_0] - 2020-03-17

### Changed

- Move spans per request to configuration for zipkin plugin [#493]
- Revert "Remove some non-tracing changes from v0.16 - merge them later… [#494]
- Add missing source_category_replace_dash to systemd conf. [#483]
- change the dynamic namespace env variable to be fluentd namespace [#471]
- Remove white characters from the line ends [#501]
- Expose otelcol UDP enpoints too [#499]
- Bump version to 0.17.0 [#502]

[v0_17_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.17.0
[#493]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/493
[#494]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/494
[#483]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/483
[#471]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/471
[#501]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/501
[#499]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/499
[#502]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/502

## [v0.16.0][v0_16_0] - 2020-03-12

### Changed

- [1.0.0] Bump fluentd image version to fix fluentd buffer bug [#426]
- [1.0.0] Revert "Revert "[breaking change] Add pre-upgrade hook for setup"" [#446]
- [1.0.0] Expose Fluentd config without ENV vars - take 3 [#428]
- [1.0.0] Persistence volume [#429]
- [1.0.0] Revert "Revert 116 metrics with filter" [#451]
- Use endpoint for tracing from values.yaml [#452]
- Strip empty fields from sending [#455]
- [1.0.0] move the statefulsets and deployment configs under root level keys [#453]
- Refactor otelcolDeployment into deployment as it's under the otelcol … [#456]
- Add more attributes extracted for traces [#438]
- Fix typo in tag name [#459]
- downgrade falco helm chart to 1.1.0 [#457]
- Prevent fluentd from handling records containing its own logs. [#460]
- Bump otelcol and remove unused tags [#468]
- Improve zipkin plugins [#469]
- Support tracing in filter plugin [#463]
- Expose setting resource constraints for helm dependencies [#464]
- Clarify params in values.yaml [#472]
- revert all 1.0.0 changes [#473]
- Make Otelcol listen on 0.0.0.0 rather than localhost [#474]
- Remove letter v from tags for developmend builds [#477]
- Allow for alpha and beta builds on Travis [#478]
- Fix gem prerelease builds for dev and pre-release [#479]
- Do not drop record in filter if it's 'broken' [#480]
- Set new release 0.16.0 [#481]
- Set the 0.16.0-rc.1 image for the future rc.1 release tests [#489]
- [WIP] Use memory_limiter and better batch settings [#488]
- Revert "Bump version in the docs to v0.16.0" [#490]
- Prerelease docs and version bump [#491]

[v0_16_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.16.0
[#426]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/426
[#446]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/446
[#428]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/428
[#429]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/429
[#451]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/451
[#452]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/452
[#455]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/455
[#453]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/453
[#456]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/456
[#438]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/438
[#459]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/459
[#457]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/457
[#460]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/460
[#468]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/468
[#469]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/469
[#463]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/463
[#464]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/464
[#472]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/472
[#473]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/473
[#474]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/474
[#477]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/477
[#478]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/478
[#479]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/479
[#480]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/480
[#481]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/481
[#489]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/489
[#488]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/488
[#490]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/490
[#491]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/491

## [v0.15.0][v0_15_0] - 2020-02-21

### Changed

- use yq in build script to generate overrides yamls [#421]
- Update Troubleshooting docs for Helm [#406]
- Support new 1.16 metrics with filter to exclude deprecated metrics [#401]
- add error handling on JSON parsing for the multiline fix [#423]
- remove cluster label from prometheus config in values.yaml [#422]
- Update configuration for helm [#417]
- add check for multiline in the multiline record transformer [#427]
- Revert 116 metrics with filter [#432]
- Zipkin plugins [#411]
- Adds the opentelemetry collector [#424]
- Fix fluentd zipkin json parsing [#433]
- Support custom release and namespace [#431]
- Update Helm requirement to 2.12+ [#378]
- add clarifying doc for helm upgrades [#437]
- add affinity config in fluentd deployment [#436]
- Cut release 0.15.0 [#441]

[v0_15_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.15.0
[#421]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/421
[#406]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/406
[#401]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/401
[#423]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/423
[#422]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/422
[#417]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/417
[#427]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/427
[#432]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/432
[#411]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/411
[#424]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/424
[#433]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/433
[#431]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/431
[#378]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/378
[#437]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/437
[#436]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/436
[#441]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/441

## [v0.14.0][v0_14_0] - 2020-02-12

### Changed

- use proper heading format [#371]
- Prometheus fix for k8s 1.16 [#370]
- fix typo in prometheus metrics regex [#373]
- freno-helm3 [#369]
- Modify regexes to match both deprecated and new metrics in 1.16 [#372]
- Bump falco helm chart dep to 1.1.1 [#376]
- Add support for data persistence [#351]
- Modify the default multiline regex to be more flexible [#380]
- expose cache params for enhance_k8s_metadata plugin [#379]
- Remove sumologic.endpoint from installation commands. [#381]
- Add back and expose source category for events source [#377]
- fix discrepancy in metadata cache ENV name [#382]
- Add missing double quotes [#383]
- Rename statefulset configs to avoid breaking change [#387]
- Change podManagementPolicy to Parallel for statefulsets [#388]
- Add async cache and expose refresh interval in values.yaml [#386]
- change buffer params [#392]
- Revert "Modify regexes to match both deprecated and new metrics in 1.16" [#391]
- Revert PV and statefulset related changes [#390]
- Change cache refresh interval to 30 min [#394]
- Add ebpf enable to helm_installation for GKE [#393]
- Increase the default number of output threads to 8 [#396]
- add generic fluentd pipeline to catch all logs [#403]
- comment out libsonnet stuff [#410]
- Add common configuration and troubleshooting tasks [#408]
- filter fluentd container logs [#402]
- Fix typo in container logs pipeline [#413]
- Cut release 0.14.0 [#415]

[v0_14_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.14.0
[#371]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/371
[#370]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/370
[#373]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/373
[#369]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/369
[#372]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/372
[#376]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/376
[#351]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/351
[#380]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/380
[#379]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/379
[#381]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/381
[#377]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/377
[#382]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/382
[#383]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/383
[#387]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/387
[#388]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/388
[#386]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/386
[#392]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/392
[#391]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/391
[#390]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/390
[#394]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/394
[#393]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/393
[#396]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/396
[#403]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/403
[#410]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/410
[#408]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/408
[#402]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/402
[#413]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/413
[#415]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/415

## [v0.13.0][v0_13_0] - 2020-01-15

### Changed

- Include buffer.output.conf for events configmap [#327]
- Fix ambiguity in helm install command [#336]
- Add Sumo Logic icon, home, sources to Helm Chart yaml [#340]
- Add HorizontalPodAutoscaler for fluentd [#339]
- Clean Prometheus container metrics [#345]
- 1.14+-fixes-support [#344]
- [breaking change] Add pre-upgrade hook for setup [#335]
- Improve fluentd liveness probe [#343]
- Change default fluentd log level to ERROR [#350]
- Clarify usage of envFromSecret to specify env variables needed [#353]
- revert readiness probe for events deployment [#355]
- fix missing aggregate container metrics [#354]
- Revert "[breaking change] Add pre-upgrade hook for setup" [#357]
- disable metrics-server dependency by default [#358]
- Change events deployment readiness probe [#360]
- Remove source categories from source creation in terraform script [#349]
- Clean up unused files [#362]
- Re-add tiller-rbac.yaml [#364]
- SUMO-124885 attach logs metadata as fields for all log formats [#359]
- cut release 0.13.0 [#365]

[v0_13_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.13.0
[#327]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/327
[#336]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/336
[#340]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/340
[#339]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/339
[#345]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/345
[#344]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/344
[#335]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/335
[#343]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/343
[#350]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/350
[#353]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/353
[#355]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/355
[#354]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/354
[#357]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/357
[#358]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/358
[#360]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/360
[#349]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/349
[#362]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/362
[#364]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/364
[#359]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/359
[#365]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/365

## [v0.12.0][v0_12_0] - 2019-12-02

### Changed

- Missed indentation in this file [#292]
- Improve Docs [#298]
- #293 facilitate gitops better through sourced secrets in setup Chart [#295]
- Bump Chart Versions [#299]
- fix missing secret ref [#300]
- Update helm installation/upgrade notes on collector name [#303]
- Use fully-qualified name for fluent-bit DNS resolution [#304]
- Customizable annotations for setup resources [#302]
- Fix alpha helm chart installation [#307]
- Add Jsonnet mixin for deploying alongside kube-prometheus [#283]
- Add Alpha Release Guide to Docs [#308]
- Autoupdate kube-prometheus mixin [#309]
- Pin Travis CI Snap Helm version to 2.16 [#312]
- Fix libsonnet generation [#315]
- Fix Multiline support for kubernetes collection [#313]
- Add note about version flag for helm upgrade [#320]
- Increase fluent-bit flush interval to lessen DNS load [#319]
- Use empty endpoint URL by default for redirection [#321]
- Add a note for helm 3 support [#323]
- cleanup fluentd sumologic filter plugin [#310]
- Update the instructions for FluentD configuration changes [#324]
- fix filter plugin error with kubernetes_meta_reduce [#325]
- FluentD file buffer [#322]
- Cut release 0.12.0 [#326]

[v0_12_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.12.0
[#292]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/292
[#298]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/298
[#295]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/295
[#299]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/299
[#300]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/300
[#303]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/303
[#304]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/304
[#302]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/302
[#307]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/307
[#283]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/283
[#308]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/308
[#309]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/309
[#312]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/312
[#315]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/315
[#313]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/313
[#320]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/320
[#319]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/319
[#321]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/321
[#323]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/323
[#310]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/310
[#324]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/324
[#325]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/325
[#322]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/322
[#326]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/326

## [v0.11.0][v0_11_0] - 2019-11-13

### Changed

- Update Travis CI to support PR push [#262]
- using include statement vs template for better yaml support [#264]
- Fix helper template variables [#267]
- Update setup.sh to use Terraform [#249]
- Start pushing alpha helm chart releases with every alpha build [#269]
- Add helm repo update [#270]
- Fix helm package to also update dependencies [#271]
- Fix git ignore for helm [#272]
- ClusterName override in Base [#273]
- Add empty setup job yaml in preparation for yaml generation [#279]
- Generate setup job yaml from helm template [#280]
- Add setup as pre-upgrade hook [#281]
- Bump Dockerfile Sumo TF provider to 2.0.0 [#282]
- Update SUMO_ENDPOINT refs to SUMO_API_ENDPOINT [#286]
- Revert pre-upgrade hook for now for further testing [#288]
- Cut release 0.11.0 [#287]
- Also build version branches [#290]
- Fix branch/tag regex validation [#291]

[v0_11_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.11.0
[#262]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/262
[#264]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/264
[#267]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/267
[#249]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/249
[#269]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/269
[#270]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/270
[#271]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/271
[#272]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/272
[#273]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/273
[#279]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/279
[#280]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/280
[#281]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/281
[#282]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/282
[#286]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/286
[#288]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/288
[#287]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/287
[#290]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/290
[#291]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/291

## [v0.10.0][v0_10_0] - 2019-10-29

### Changed

- Scaling Fluentd [#235]
- Bump version of Fluentd Output plugin to support fields [#247]
- Update steps for installing side Prometheus [#236]
- Dockerfile changes for Terraform support [#248]
- optimize remote write settings [#250]
- Re-add wget dependency for setup.sh script [#251]
- bump output plugin version to 1.6.1 [#252]
- Fix grafana from starting via Helm deployment [#253]
- Fix etcd_request_cache\_(get|add)\_latencies_summary to wildcard match [#254]
- Add NodeSelector and Tolerations to both deployments [#256]
- Cut release 0.10.0 [#258]

[v0_10_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.10.0
[#235]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/235
[#247]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/247
[#236]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/236
[#248]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/248
[#250]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/250
[#251]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/251
[#252]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/252
[#253]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/253
[#254]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/254
[#256]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/256
[#258]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/258

## [v0.9.0][v0_9_0] - 2019-10-10

### Changed

- update overview image in main readme to include Falco [#208]
- Pin gem dependency versions; Fix metadata version string [#221]
- Fix fluentd log level parameter [#225]
- Add instructions on deploying second prometheus in the same cluster [#224]
- Bump falco chart version to 1.0.8 for EKS fix [#226]
- check exact secret name in setup script [#227]
- Bump fluent-plugin-prometheus version to fix breaking change from prometheus-client [#229]
- Cut release 0.9.0 [#230]

[v0_9_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.9.0
[#208]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/208
[#221]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/221
[#225]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/225
[#224]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/224
[#226]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/226
[#227]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/227
[#229]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/229
[#230]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/230

## [v0.8.0][v0_8_0] - 2019-09-26

### Changed

- Skip generated yaml check for TRAVIS_TAG builds [#217]
- Fix Container Metrics Routing [#218]
- Cut 0.8.0 [#220]

[v0_8_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.8.0
[#217]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/217
[#218]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/218
[#220]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/220

## [v0.7.0][v0_7_0] - 2019-09-24

### Changed

- accesskey should be accessKey [#196]
- Add setup job troubleshooting steps [#199]
- Add prerequisite on endpoint and access key [#201]
- Add flag to disable events collection in helm [#205]
- feat(deployment.yaml): Updated to expose the EXCLUDE NAMESPACE and ot… [#206]
- Cut 0.7.0 [#213]

[v0_7_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.7.0
[#196]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/196
[#199]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/199
[#201]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/201
[#205]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/205
[#206]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/206
[#213]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/213

## [v0.6.0][v0_6_0] - 2019-09-13

### Changed

- Cut 0.5.0 release [#192]
- Cut 0.6.0 [#193]

[v0_6_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.6.0
[#192]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/192
[#193]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/193

## [v0.5.0][v0_5_0] - 2019-09-13

### Changed

- SUMO-117711: Prevent Grafana from deploying with Helm collection chart [#177]
- Pin patch version of helm dependencies [#178]
- Add sed for prometheus namespaceSelector [#179]
- Pre-install hook for helm [#176]
- RBAC for pre-install hook [#181]
- Simplify Metrics FluentD Pipeline [#180]
- Assign weight to pre-install hooks [#185]
- fix setup curl command url [#188]

[v0_5_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.5.0
[#177]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/177
[#178]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/178
[#179]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/179
[#176]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/176
[#181]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/181
[#180]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/180
[#185]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/185
[#188]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/188

## [v0.4.0][v0_4_0] - 2019-09-03

### Changed

- Remove symlinks to legacy helm override files [#154]
- SUMO-117653: Change docker image pull policy to IfNotPresent [#165]
- fix labels, disable Fluent-Bit Helm Chart serviceMonitor, use Prometheus Operator additionalServiceMonitors to work around expectation
  that Prometheus Operator is already installed. [#159]
- Git ignore Helm chart deps [#166]
- Migrate kubernetes_sumologic filter plugin [#167]
- SUMO-117261: Skip using TRAVIS_COMMIT_RANGE for yaml detection [#168]
- Fix Helm template naming in yaml files [#174]
- Cut 0.4.0 [#175]

[v0_4_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.4.0
[#154]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/154
[#165]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/165
[#159]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/159
[#166]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/166
[#167]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/167
[#168]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/168
[#174]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/174
[#175]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/175

## [v0.3.0][v0_3_0] - 2019-08-29

### Changed

- Get rid of unstaged changes before switching to gh-pages branch [#155]
- Drop labels with empty values [#157]
- Cut 0.3.0 [#158]

[v0_3_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.3.0
[#155]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/155
[#157]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/157
[#158]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/158

## [v0.2.0][v0_2_0] - 2019-08-29

### Changed

- Bump yaml version to 0.1.0 [#134]
- Note On Possible Remote Write Update Changes [#127]
- Added Falco specific changes. [#102]
- Sync helm chart yaml and fix service selector [#135]
- Add check for required software before running script to prevent issu… [#136]
- Move fluent-bit INPUT config to overrides yaml [#140]
- Generate yaml from helm chart on commits [#137]
- Fix failing master builds [#143]
- Only pass in our own yamls to helm template cmd [#148]
- Automate helm chart release in setup.sh [#147]
- SUMO-115354 Add dependencies with overridden values.yaml [#132]
- Add falco as sumologic chart dependency [#150]
- Fix labels for k8s health check metrics and use versioned overrides yaml files [#152]
- Cut release 0.2.0 [#153]

[v0_2_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.2.0
[#134]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/134
[#127]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/127
[#102]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/102
[#135]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/135
[#136]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/136
[#140]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/140
[#137]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/137
[#143]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/143
[#148]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/148
[#147]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/147
[#132]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/132
[#150]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/150
[#152]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/152
[#153]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/153

## [v0.1.0][v0_1_0] - 2019-08-08

### Changed

- Enhanced metadata for Logs [#73]
- Fix remote storage regex prometheus override [#93]
- Don't build/push docker image with latest tag [#95]
- Parameterize buffer settings for Fluentd Logs/Metrics [#99]
- Fix setup.sh bash script issues [#100]
- add development disclaimer [#101]
- Auto-tag alpha images in Git that we can generate full releases from [#103]
- Use Github token to push tags [#104]
- Skip pushing again for alpha tagged builds [#105]
- Move Dockerfile env variables to yaml file to avoid drift [#107]
- Use v1 (non-beta) API for ClusterRole, ClusterRoleBinding [#111]
- SUMO-115364 Handle exceptions thrwon from kubeclient calls [#106]
- enable fluent-bit metrics collection [#112]
- Add monitoring for FluentD plugins [#108]
- bump fluentd-kubernetes-sumologic v2.4.2 [#114]
- Add param for alpha docker images [#113]
- Tolerate any NoScheule taint regardless of key [#119]
- Update README with events collection [#40]
- Fix service monitor [#120]
- k8s_collection_diagram [#122]
- Bump versions of plugins used in Dockerfile [#121]
- Optionally deploy and download yaml in setup.sh [#124]
- Switch to Debian fluentd Dockerfile [#125]
- Helm Chart initial commit [#118]
- SUMO-114676: Use multi-stage Docker build to reduce image size [#128]

[v0_1_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.1.0
[#73]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/73
[#93]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/93
[#95]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/95
[#99]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/99
[#100]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/100
[#101]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/101
[#103]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/103
[#104]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/104
[#105]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/105
[#107]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/107
[#111]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/111
[#106]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/106
[#112]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/112
[#108]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/108
[#114]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/114
[#113]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/113
[#119]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/119
[#40]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/40
[#120]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/120
[#122]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/122
[#121]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/121
[#124]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/124
[#125]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/125
[#118]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/118
[#128]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/128

## [v0.0.0][v0_0_0] - 2019-07-25

### Changed

- Byi initial skeletons [#1]
- datapoint plugin [#3]
- Byi carbonv2 plugin [#5]
- protobuf parser plugin [#4]
- Byi deploy metrics [#6]
- rename `_sourceType` to `_origin` [#9]
- space_as parameter [#7]
- move \_origin to meta tag [#10]
- Byi helm yaml [#11]
- select metrics [#12]
- Split metrics to multiple http sources [#13]
- Byi fix timeseries [#14]
- Prometheus format filter plugin [#15]
- Byi override yaml update [#16]
- Upload image diagram for readme [#17]
- Byi tweak remote write [#18]
- rename from pod_name/container_name to pod/container [#19]
- Use prometheus format for metrics [#20]
- Byi setup script [#21]
- Byi remove container eq pod [#22]
- Byi more replicas [#23]
- Collect additional metrics [#24]
- refine deployment script [#25]
- add stateful set metrics [#27]
- script fixing [#28]
- plugin scaffold [#30]
- add into docker image [#31]
- implement enhance-k8s-metadata plugin with label reading [#33]
- Added in the working_set_bytes metric [#36]
- Collect logs with FluentBit and Fluentd [#34]
- Events plugin [#35]
- Update setup script for logs and events [#38]
- Combine events yaml file with logs and metrics one [#39]
- Increase the resource limits on CPU and memory for fluentd deployment [#43]
- Byi oweners ref [#37]
- ensure proper permissions for events... [#46]
- fix-pod-name-including-filepath [#47]
- Restarts Count for pods :) [#44]
- Added a metric to track files on the nodes [#49]
- CPU % extra metrics [#45]
- Forwarding all Remote Write Metrics [#42]
- Fix events plugin [#48]
- Added packet dropping as a metric we pick up [#50]
- Add configurable event type filter [#51]
- Nik automation friendly [#52]
- Fix setup.sh [#55]
- Fix missing metrics [#56]
- Custom Metrics [#58]
- Change the path example [#59]
- Fix Travis Integration [#61]
- Parameterize resource name to support watching other resources in events plugin [#62]
- Add service metadata monitoring [#57]
- enable logical default source category for all http sources [#66]
- disable Alertmanager and Grafana by default. [#64]
- Use fluentd helper function [#65]
- SUMO-111064 Add unit test for events plugin [#63]
- Update default label behaviour for metadata enhancement plugin [#60]
- Fix order of assert_equal in test files [#67]
- Use different label in events deployment [#69]
- Attach service metadata [#68]
- use v1.5.0 for output plugin [#70]
- use-fields-log-format [#71]
- Add overview image to main repo README [#72]
- fix automatic setup script command in deploy README [#76]
- Include namespace parameter in help usage [#78]
- Make imagePullPolicy and latest tag explicit for now [#77]
- Initialize @pods_to_services before timer_execute [#80]
- Add "patch" configmaps capability for fluentd [#79]
- Disable service metadata for now [#81]
- SUMO-113170 Support different k8s api versions [#74]
- Cleanup Dockerfile and remove Dockerfile-debian [#82]
- Upgrade Dockerfile fluentd to v1.6.2 [#87]
- Restructure Helm overrides directory [#88]
- Strip alpha suffix from gem version to avoid prerelease behavior [#90]

[v0_0_0]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v0.0.0
[#1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1
[#3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/3
[#5]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/5
[#4]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/4
[#6]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/6
[#9]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/9
[#7]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/7
[#10]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/10
[#11]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/11
[#12]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/12
[#13]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/13
[#14]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/14
[#15]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/15
[#16]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/16
[#17]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/17
[#18]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/18
[#19]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/19
[#20]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/20
[#21]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/21
[#22]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/22
[#23]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/23
[#24]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/24
[#25]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/25
[#27]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/27
[#28]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/28
[#30]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/30
[#31]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/31
[#33]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/33
[#36]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/36
[#34]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/34
[#35]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/35
[#38]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/38
[#39]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/39
[#43]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/43
[#37]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/37
[#46]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/46
[#47]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/47
[#44]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/44
[#49]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/49
[#45]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/45
[#42]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/42
[#48]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/48
[#50]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/50
[#51]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/51
[#52]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/52
[#55]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/55
[#56]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/56
[#58]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/58
[#59]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/59
[#61]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/61
[#62]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/62
[#57]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/57
[#66]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/66
[#64]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/64
[#65]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/65
[#63]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/63
[#60]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/60
[#67]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/67
[#69]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/69
[#68]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/68
[#70]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/70
[#71]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/71
[#72]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/72
[#76]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/76
[#78]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/78
[#77]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/77
[#80]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/80
[#79]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/79
[#81]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/81
[#74]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/74
[#82]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/82
[#87]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/87
[#88]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/88
[#90]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/90
