#!/bin/bash

readonly SCRIPT_PATH="$( dirname "$(realpath "${0}")" )"
touch "${SCRIPT_PATH}"/../values.local.yaml
