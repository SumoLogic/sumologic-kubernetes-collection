# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- otelcol: add systemd logs pipeline (#1767)

  - This change introduces logs metadata enrichment with Sumo Open Telemetry
    distro for systemd logs.

    One notable change in behavior with respect to `fluentd` is that
    `.Values.fluentd.logs.systemd.sourceName` is respected and
    will set `_sourceName` of processed logs while fluentd would set this field
    to the corresponding systemd serice's name e.g. `docker` for `docker.service`.

## [v2.1.5][v2_1_5] - 2021-07-21

### Changed

- fix(deps): Upgrade Fluentd from `v1.12.2-sumo-0` to `v1.12.2-sumo-2` #1693

[v2_1_5]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.1.5
