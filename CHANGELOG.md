# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

- chore(deps): upgrade fluentd image to `1.12.2-sumo-5` [#1829][#1829]

  Updates version of fluentd-output-sumologicplugin to [1.7.3][1.7.3]

- feat(logs): upgrade fluent-bit chart to v0.19.1 [#1824]

  This upgrades Fluent Bit to v1.8.8.

- Update falco subchart to 1.11.1 [#1618][#1618]

[#1618]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1618
[#1767]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1767
[#1824]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1824
[#1829]: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1829
[1.7.3]: https://github.com/SumoLogic/fluentd-output-sumologic/releases/tag/1.7.3

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
