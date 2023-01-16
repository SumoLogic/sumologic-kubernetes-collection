#!/usr/bin/env bash

# shellcheck disable=SC2154

err_report() {
    echo "Script error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

function helm() {
  docker run --rm \
    -v "$(pwd):/chart" \
    -w /chart \
    sumologic/kubernetes-tools:2.13.0 \
    helm "$@"
}

function set_up_github() {
  git config --global user.email "continuous-integration@sumologic.com"
  git config --global user.name "Continuous Integration [bot]"
}

function push_helm_chart() {
  local version="$1"
  local chart_dir="$2"
  local sync_dir="./tmp-helm-sync"
  local remote="origin"

  echo "Pushing new Helm Chart release ${version}"

  set -ex
  # this loop is to allow for concurent builds: https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1853 
  while true; do
    # due to helm repo index issue: https://github.com/helm/helm/issues/7363
    # we need to create new package in a different dir, merge the index and move the package back
    mkdir -p "${sync_dir}"
    helm package deploy/helm/sumologic --dependency-update --version="${version}" --app-version="${version}" --destination "${sync_dir}"

    git fetch "${remote}" gh-pages
    git stash push
    git checkout -B gh-pages "${remote}/gh-pages"

    helm repo index --url "https://sumologic.github.io/sumologic-kubernetes-collection${chart_dir:1}/" --merge "${chart_dir}/index.yaml" "${sync_dir}"

    mv -f "${sync_dir}"/* "${chart_dir}"
    rmdir "${sync_dir}"

    git add -A
    git status
    git commit -m "Push new Helm Chart release ${version}"

    # Go back to the branch we checkout out at before gh-pages
    git checkout -
    # Pop the changes in case there are any
    # this command will fail on empty stash, hence the || true
    git stash pop || true

    if git push "${remote}" gh-pages; then
      # Push was successful, we're done
      break
    fi
  done
  set +ex
}

function is_checkout_on_tag() {
  git describe --exact-match --tags HEAD 2>/dev/null
}

function fetch_current_branch() {
  # No need to fetch when we can already do 'git describe ...'
  git describe --tags >/dev/null && return

  # No need to fetch full history with:
  # git fetch --tags --unshallow
  # Just fetch the current branch and its tags so that git describe works.
  local BRANCH
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"

  # Need to check if repo is shallow because:
  # "fatal: --unshallow on a complete repository does not make sense"
  # and we need to unshallow the repository because otherwise we'd get:
  # fatal: No tags can describe '<SHA>'.
  # Try --always, or create some tags.
  if [[ "true" == "$(git rev-parse --is-shallow-repository)" ]]; then
    git fetch -v --tags --unshallow origin "${BRANCH}"
  else
    git fetch -v --tags origin "${BRANCH}"
  fi
}
