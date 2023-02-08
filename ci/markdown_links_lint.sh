#!/usr/bin/env bash

set -euo pipefail

GREP="grep"
OS="$(uname -s)"
if [[ "${OS}" == "Darwin" ]]; then
    GREP="ggrep"
fi

if ! command -v "${GREP}" ; then
    echo "${GREP} is missing from the system, please install it."
    exit 1
fi

# Get all markdown files
readonly FILES=$(find . -type f -name '*.md')

RET_VAL=0

for file in ${FILES}; do
    # '\[[^\]]*\]\([^\)]*\)' - get all markdown links [*](*)
    # filter in only linked to this repository
    # filter out all links pointing to specific release, tag or commit
    # filter out links ended with /releases
    if "${GREP}" -HnoP '\[[^\]]*\]\([^\)]*\)' "${file}" \
        | "${GREP}" 'github.com/sumologic/sumologic-kubernetes-collection' \
        | "${GREP}" -vP '(\/(blob|tree)\/(v\d+\.|[a-f0-9]{40}\/|release\-))' \
        | "${GREP}" -vP '\/releases\)'; then
    
        RET_VAL=1
    fi
done

exit "${RET_VAL}"
