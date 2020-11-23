#!/bin/bash

# shellcheck disable=SC2154
VERSION="${TRAVIS_TAG:-0.0.0}"
# shellcheck disable=SC2154
VERSION="${VERSION#v}"
: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"
: "${DOCKER_USERNAME:=sumodocker}"

echo "Starting build process in: $(pwd) with version tag: ${VERSION}"
err_report() {
    echo "Script error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

function helm() {
  docker run --rm \
    -v "$(pwd):/chart" \
    -w /chart \
    sumologic/kubernetes-tools:2.0.0 \
    helm "$@"
}

function get_branch_to_checkout() {
  [[ "${TRAVIS_EVENT_TYPE}" == pull_request ]] \
    && echo "${TRAVIS_PULL_REQUEST_BRANCH}" \
    || echo "${TRAVIS_BRANCH}"
}

function bundle_fluentd_plugin() {
  local plugin_name="${1}"
  local version="${2}"
  # Strip everything after "-" (longest match) to avoid gem prerelease behavior
  local gem_version="${version%%-*}"

  if [[ -z "${version}" ]] ; then
    echo "Please provide the version when bundling fluentd plugins"
    exit 1
  fi
  pushd "${plugin_name}" || exit 1

  echo "Building gem ${plugin_name} version ${gem_version} in $(pwd) ..."
  sed -i.bak "s/0.0.0/${gem_version}/g" ./"${plugin_name}".gemspec
  rm -f ./"${plugin_name}".gemspec.bak

  echo "Install bundler..."
  bundle install

  echo "Build gem ${plugin_name} ${gem_version}..."
  gem build "${plugin_name}"
  mv ./*.gem ../deploy/docker/gems
  popd || exit 1
}

function bundle_fluentd_plugins() {
  local version="${1}"

  if [[ -z "${version}" ]] ; then
    echo "Please provide the version when bundling fluentd plugins"
    exit 1
  fi

  find . -maxdepth 1 -name 'fluent-plugin-*' -type 'd' -print |
    while read -r line; do
      # Run tests in their own context
      (bundle_fluentd_plugin "$(basename "${line}")" "${version}") || exit 1
    done
}

function set_up_github() {
  local token="${1}"
  local branch="${2}"

  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
  git remote add origin-repo "https://${token}@github.com/SumoLogic/sumologic-kubernetes-collection.git" > /dev/null 2>&1
  git fetch --unshallow origin-repo

  readonly branch="$(get_branch_to_checkout)"
  echo "Checking out the ${branch} branch..."
  git checkout "${branch}"
}

function push_docker_image() {
  local version="$1"

  echo "Tagging docker image ${DOCKER_TAG}:local with ${DOCKER_TAG}:${version}..."
  docker tag "${DOCKER_TAG}:local" "${DOCKER_TAG}:${version}"
  echo "Pushing docker image ${DOCKER_TAG}:${version}..."
  echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
  docker push "${DOCKER_TAG}:${version}"
}

function push_helm_chart() {
  local version="$1"
  local chart_dir="$2"
  local sync_dir="./tmp-helm-sync"

  echo "Pushing new Helm Chart release ${version}"
  set -x

  git checkout -- .

  # due to helm repo index issue: https://github.com/helm/helm/issues/7363
  # we need to create new package in a different dir, merge the index and move the package back
  mkdir -p "${sync_dir}"
  helm package deploy/helm/sumologic --dependency-update --version="${version}" --app-version="${version}" --destination "${sync_dir}"

  git fetch origin-repo
  git checkout gh-pages

  helm repo index --url "https://sumologic.github.io/sumologic-kubernetes-collection${chart_dir:1}/" --merge "${chart_dir}/index.yaml" "${sync_dir}"

  mv -f "${sync_dir}"/* "${chart_dir}"
  rmdir "${sync_dir}"

  git add -A
  git commit -m "Push new Helm Chart release ${version}"
  git push --quiet origin-repo gh-pages
  set +x
}

function build_docker_image() {
  local tag
  local no_cache
  tag="${1}"

  echo "Building docker image with ${tag}:local in $(pwd)..."
  pushd ./deploy/docker || exit 1
  cp ../helm/sumologic/conf/setup/main.tf . || exit 1
  no_cache="--no-cache"
  if [[ "${DOCKER_USE_CACHE}" == "true" ]]; then
    no_cache=""
  fi
  docker build . -f ./Dockerfile -t "${tag}:local" ${no_cache:+"--no-cache"}
  rm main.tf
  rm -f ./gems/*.gem
  popd || exit 1

  echo "Test docker image locally..."
  ruby deploy/test/test_docker.rb || exit 1
}

# Set up Github
if [ -n "${GITHUB_TOKEN}" ]; then
  set_up_github "${GITHUB_TOKEN}" "$(get_branch_to_checkout)"
fi

bundle_fluentd_plugins "${VERSION}" || (echo "Failed bundling fluentd plugins" && exit 1)
build_docker_image "${DOCKER_TAG}" || (echo "Error during building docker image" && exit 1)

if [ -n "${DOCKER_PASSWORD}" ] && [ -n "${TRAVIS_TAG}" ]; then
  push_docker_image "${VERSION}"
  push_helm_chart "${VERSION}" "."

elif [ -n "${DOCKER_PASSWORD}" ] && [[ "${TRAVIS_BRANCH}" == "master" || "${TRAVIS_BRANCH}" =~ ^release-v[0-9]+\.[0-9]+$ ]] && [ "${TRAVIS_EVENT_TYPE}" == "push" ]; then
  dev_build_tag=$(git describe --tags --always)
  dev_build_tag=${dev_build_tag#v}
  push_docker_image "${dev_build_tag}"
  push_helm_chart "${dev_build_tag}" "./dev"

else
  echo "Skip Docker pushing"
fi

echo "DONE"
