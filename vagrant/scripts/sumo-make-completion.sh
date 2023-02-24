#!/usr/bin/env bash

set -euo pipefail

targets=$(grep -oE '^\S*\:' /sumologic/vagrant/Makefile | sed 's/\:$//g')
complete -W "${targets}" sumo-make

# Restore default behavior for bash
set +euo pipefail
