#!/usr/bin/env bash

# This scripts checks for unused helm template definitions
TEMPLATES=$(cat deploy/helm/sumologic/templates/_helpers/*.tpl | grep define | grep -oP '".*?"' || true)
RETURN=0
for template in ${TEMPLATES}; do
    if ! grep -P "(template|include) ${template}" deploy/helm/sumologic -R > /dev/null; then
        echo "${template}";
        RETURN=1
    fi
done

exit "${RETURN}"
