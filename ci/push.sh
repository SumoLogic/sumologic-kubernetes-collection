#!/usr/bin/env bash

# shellcheck disable=SC2154

# shellcheck disable=SC1090
source "${BASH_SOURCE[0]}"/_build_functions.sh

VERSION="${TRAVIS_TAG:-0.0.0}"
VERSION="${VERSION#v}"
: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"
: "${DOCKER_USERNAME:=sumodocker}"

echo "Starting push in: $(pwd) with version tag: ${VERSION}"

if [[ -z "${DOCKER_PASSWORD}" ]]; then
  echo "Provide DOCKER_PASSWORD in order to push built image to container registry"
  exit 1
fi

# Set up Github
if [ -n "${GITHUB_TOKEN}" ]; then
  set_up_github "${GITHUB_TOKEN}" "$(get_branch_to_checkout)"
fi

if [ -n "${TRAVIS_TAG}" ]; then
  push_docker_image "${VERSION}"
  push_helm_chart "${VERSION}" "."

elif [[ "${TRAVIS_BRANCH}" == "main" || "${TRAVIS_BRANCH}" =~ ^release-v[0-9]+\.[0-9]+$ ]] && [ "${TRAVIS_EVENT_TYPE}" == "push" ]; then
  dev_build_tag=$(git describe --tags --always)
  dev_build_tag=${dev_build_tag#v}
  push_docker_image "${dev_build_tag}"
  push_helm_chart "${dev_build_tag}" "./dev"

else
  echo "Skip Docker pushing"
fi

echo "DONE"
