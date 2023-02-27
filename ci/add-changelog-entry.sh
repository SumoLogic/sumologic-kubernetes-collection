#!/usr/bin/env bash

# This is a simple interactive script for adding changelog entries.

set -euo pipefail

function get_default_change_type() {
    local text
    readonly text="${1}"
    readonly commit_type="${text%[(:]*}"

    local change_type
    case "${commit_type}" in
    fix )
        change_type="fixed"
        ;;
    feat )
        change_type="added"
        ;;
    * )
        change_type="changed"
    esac
    echo "${change_type}"
}

function get_default_pr_number() {
    local existing_pr_number
    local commit_hash
    commit_hash=$(git show -s --format=%h)
    existing_pr_number=$(curl -s "https://api.github.com/repos/SumoLogic/sumologic-kubernetes-collection/commits/${commit_hash}/pulls?per_page=1" | jq '.[0].number' 2>/dev/null)
    if [[ -n "${existing_pr_number}" && "${existing_pr_number}" != "null" ]]; then
        echo "${existing_pr_number}"
        return
    fi

    local latest_pr_number
    latest_pr_number=$(curl -s "https://api.github.com/repos/SumoLogic/sumologic-kubernetes-collection/issues?state=all&per_page=1" | jq '.[0].number')
    echo "$((latest_pr_number + 1))"
}

DEFAULT_TEXT="$(git show -s --format=%s || true)"
DEFAULT_CHANGE_TYPE="$(get_default_change_type "${DEFAULT_TEXT}")"
DEFAULT_PR_NUMBER="$(get_default_pr_number)"

echo -e "Generating changelog entry"

echo -e "Enter the ID of your Pull Request."
read -rp "Leave blank to use default (${DEFAULT_PR_NUMBER}) " PR_ID
PR_NUMBER="${PR_ID###}"  # this removes a leading # if present
PR_NUMBER="${PR_NUMBER:-${DEFAULT_PR_NUMBER}}"

echo -e "Enter the type of your change. Available types are: breaking, changed, added, fixed"
read -rp "Leave blank to use default (${DEFAULT_CHANGE_TYPE}) " CHANGE_TYPE
CHANGE_TYPE="${CHANGE_TYPE:-${DEFAULT_CHANGE_TYPE}}"

echo -e "Enter the text for your changelog entry."
read -rp "Leave blank to use default (\"${DEFAULT_TEXT}\") " ENTRY_TEXT
ENTRY_TEXT="${ENTRY_TEXT:-${DEFAULT_TEXT}}"

towncrier create -c "${ENTRY_TEXT}" "${PR_NUMBER}.${CHANGE_TYPE}.txt"

