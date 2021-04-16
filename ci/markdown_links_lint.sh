#!/usr/bin/env bash

# Get all markdown files
readonly FILES=$(find . -type f -name '*.md')

RET_VAL=0

for file in ${FILES}; do
    # '\[[^\]]*\]\([^\)]*\)' - get all markdown links [*](*)
    # filter in only linked to this repository
    # filter out all links pointing to specific release, tag or commit
    # filter out links ended with /releases
    if grep -HnoP '\[[^\]]*\]\([^\)]*\)' "${file}" \
        | grep 'sumologic-kubernetes-collection' \
        | grep -vP '(\/(blob|tree)\/(v\d+\.|[a-f0-9]{40}\/|release\-))' \
        | grep -vP '\/releases\)'; then
    
        RET_VAL=1
    fi
done

exit "${RET_VAL}"
