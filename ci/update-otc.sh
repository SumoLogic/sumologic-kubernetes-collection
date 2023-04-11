#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
	echo "Expected 2 arguments, got $#."
	echo "Usage: $0 <current-otc-version> <new-otc-version>"
	echo "For example: $0 0.73.0-sumo-1 0.74.0-sumo-0"
	exit 1
fi

otc_current_version=${1}
otc_new_version=${2}

echo "Updating OTC from ${otc_current_version} to ${otc_new_version}"

sed -i "s/${otc_current_version}/${otc_new_version}/" ./deploy/helm/sumologic/README.md
sed -i "s/${otc_current_version}/${otc_new_version}/" ./deploy/helm/sumologic/values.yaml
sed -i "s/${otc_current_version}/${otc_new_version}/" ./docs/*.md
sed -i "s/${otc_current_version}/${otc_new_version}/" ./tests/helm/testdata/goldenfile/*/*.yaml

upstream_current_version=${otc_current_version%%-sumo-*}
upstream_new_version=${otc_new_version%%-sumo-*}

sed -i "s/${upstream_current_version}/${upstream_new_version}/" ./deploy/helm/sumologic/conf/events/otelcol/config.yaml
sed -i "s/${upstream_current_version}/${upstream_new_version}/" ./deploy/helm/sumologic/conf/logs/collector/otelcol/config.yaml
sed -i "s/${upstream_current_version}/${upstream_new_version}/" ./deploy/helm/sumologic/conf/logs/otelcol/config.yaml
sed -i "s/${upstream_current_version}/${upstream_new_version}/" ./deploy/helm/sumologic/conf/metrics/otelcol/*.yaml
sed -i "s/${upstream_current_version}/${upstream_new_version}/" ./docs/*.md
