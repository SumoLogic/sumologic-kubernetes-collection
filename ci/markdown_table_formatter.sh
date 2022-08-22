#!/usr/bin/env bash

# shellcheck disable=SC2086

readonly CMD="${CMD:-markdown-table-formatter}"

if ! "${CMD}" --version ; then
    echo "markdown-table-formatter not found, please install it with 'npm install markdown-table-formatter -g'"
    exit 1
fi

readonly FILES="deploy/README.md
deploy/docs/best-practices.md
deploy/docs/performance.md
deploy/helm/sumologic/README.md"


case "${1}" in
"--check")
    printf "Checking files:\n"
    printf "%s\n" ${FILES}
    "${CMD}" --check ${FILES}
    ;;

"--format")
    printf "Formatting files:\n"
    printf "%s\n" ${FILES}
    "${CMD}" ${FILES}
    ;;

*)
    echo "Unknown param ${1}"
    exit 1
    ;;
esac
