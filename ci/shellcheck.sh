#!/usr/bin/env bash

set -e

echo "Checking the bash scripts with shellcheck..."
find . ! -path '*deploy/helm/sumologic/conf/setup/setup.sh' ! -path '*deploy/helm/sumologic/conf/setup/monitors.sh' ! -path "*/tmp/*" -name '*.sh' -type 'f' -print |
    while read -r file; do
        # Run tests in their own context
        echo "Checking ${file} with shellcheck"
        shellcheck --enable all --external-sources --exclude SC2155 "${file}"
    done

find . -path '*tests/helm/terraform/static/*.output.yaml' -type 'f' -print |
    while read -r file; do
        # Run tests in their own context
        echo "Checking ${file} (setup.sh) with shellcheck"
        yq r "${file}" "data[setup.sh]" | shellcheck --enable all --external-sources --exclude SC2155 -
    done

find . -path '*tests/helm/terraform/static/*.output.yaml' -type 'f' -print |
    while read -r file; do
        # Run tests in their own context
        echo "Checking ${file} (monitors.sh) with shellcheck"
        yq r "${file}" "data[monitors.sh]" | shellcheck --enable all --external-sources --exclude SC2155 -
    done

find . -path '*tests/helm/terraform/static/*.output.yaml' -type 'f' -print |
    while read -r file; do
        # Run tests in their own context
        echo "Checking ${file} (dashboards.sh) with shellcheck"
        yq r "${file}" "data[dashboards.sh]" | shellcheck --enable all --external-sources --exclude SC2155 -
    done

find . -path '*tests/helm/terraform_custom/static/*.output.yaml' ! -path "./tests/helm/terraform_custom/static/empty.output.yaml" -type 'f' -print |
    while read -r file; do
        # Run tests in their own context
        echo "Checking ${file} (custom_setup.sh) with shellcheck"
        yq r "${file}" "data[custom_setup.sh]" | shellcheck --enable all --external-sources --exclude SC2155 -
    done
