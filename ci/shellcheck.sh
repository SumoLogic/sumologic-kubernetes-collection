#!/usr/bin/env bash

set -euo pipefail

echo "Checking the bash scripts with shellcheck..."
find . -name '*.sh' -type 'f' -print |
    while read -r file; do
        # Run tests in their own context
        echo "Checking ${file} with shellcheck"
        shellcheck --enable all --external-sources --exclude SC2155 "${file}"
    done
