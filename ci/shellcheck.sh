#!/usr/bin/env bash

set -e

echo "Checking the bash scripts with shellcheck..."
find . ! -path '*deploy/helm/sumologic/conf/setup/setup.sh' ! -path "*/tmp/*" -name '*.sh' -type 'f' -print |
    while read -r file; do
        # Run tests in their own context
        echo "Checking ${file} with shellcheck"
        shellcheck --enable all "${file}"
    done
