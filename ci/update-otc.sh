#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
	echo "Expected 2 arguments, got $#."
	echo "Usage: $0 <current-otc-version> <new-otc-version>"
	echo "For example: $0 0.73.0-sumo-1 0.74.0-sumo-0"
	exit 1
fi

OTC_CURRENT_VERSION=${1}
OTC_NEW_VERSION=${2}

echo "Updating OTC from ${OTC_CURRENT_VERSION} to ${OTC_NEW_VERSION}"

sed -i "s/${OTC_CURRENT_VERSION}/${OTC_NEW_VERSION}/" ./deploy/helm/sumologic/README.md
sed -i "s/${OTC_CURRENT_VERSION}/${OTC_NEW_VERSION}/" ./deploy/helm/sumologic/values.yaml
sed -i "s/${OTC_CURRENT_VERSION}/${OTC_NEW_VERSION}/" ./docs/security-best-practices.md
sed -i "s/${OTC_CURRENT_VERSION}/${OTC_NEW_VERSION}/" ./tests/helm/testdata/goldenfile/*/*.yaml
