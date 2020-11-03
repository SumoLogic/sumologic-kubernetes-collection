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
    sumologic/kubernetes-tools:1.0.0 \
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

  helm repo index --url https://sumologic.github.io/sumologic-kubernetes-collection/ --merge ./index.yaml "${sync_dir}"

  mv -f "${sync_dir}"/* .
  rmdir "${sync_dir}"

  git add -A
  git commit -m "Push new Helm Chart release ${version}"
  git push --quiet origin-repo gh-pages
  set +x
}

function validate_changes_to_generated_files() {
  local changes
  local recent_author

  # Check most recent commit author. If non-Travis, check for changes made to generated files
  recent_author=$(git log origin-repo/master..HEAD --format="%an" | grep -m1 "")
  if echo "${recent_author}" | grep -v -q -i "travis"; then
    # NOTE(ryan, 2019-08-30): Append "|| true" to command to ignore non-zero exit code
    changes=$(git log origin-repo/master..HEAD --name-only --format="" --author="${recent_author}" | grep -i "fluentd-sumologic.yaml.tmpl\|fluent-bit-overrides.yaml\|prometheus-overrides.yaml\|falco-overrides.yaml") || true
    if [ -n "${changes}" ]; then
      echo "Aborting due to manual changes detected in the following generated files: ${changes}"
      exit 1
    fi
  fi
}

function build_docker_image() {
  local tag
  local no_cache
  tag="${1}"

  echo "Building docker image with ${tag}:local in $(pwd)..."
  pushd ./deploy/docker || exit 1
  no_cache="--no-cache"
  if [[ "${DOCKER_USE_CACHE}" == "true" ]]; then
    no_cache=""
  fi
  docker build . -f ./Dockerfile -t "${tag}:local" ${no_cache:+"--no-cache"}
  rm -f ./gems/*.gem
  popd || exit 1

  echo "Test docker image locally..."
  ruby deploy/test/test_docker.rb || exit 1
}

function generate_overrides() {
  local with_files
  local prometheus_remote_write
  local branch

  branch="${1}"

  echo "Generating deployment yaml from helm chart..."
  echo "# This file is auto-generated." > deploy/kubernetes/fluentd-sumologic.yaml.tmpl
  helm dependency update deploy/helm/sumologic

  # Get list of templates available for default values.yaml
  with_files=$(find deploy/helm/sumologic/templates -maxdepth 1 -iname "*.yaml" ! -path "*/otelcol-*" ! -path "*/scc.yaml" ! -path "*/*hpa.yaml" ! -path "*/*psp.yaml" | sed 's#deploy/helm/sumologic/templates#-s templates#g' | sed 's/yaml/yaml /g')
  # shellcheck disable=SC2086
  helm template deploy/helm/sumologic \
    ${with_files} \
    --namespace "\$NAMESPACE" \
    --name-template collection \
    --set dryRun=true >> deploy/kubernetes/fluentd-sumologic.yaml.tmpl 2>/dev/null \
    --set sumologic.endpoint="bogus" \
    --set sumologic.accessId="bogus" \
    --set sumologic.accessKey="bogus"

  if [[ -n $(git diff deploy/kubernetes/fluentd-sumologic.yaml.tmpl) ]]; then
      echo "Detected changes in 'fluentd-sumologic.yaml.tmpl', committing the updated version to ${branch}..."
      git add deploy/kubernetes/fluentd-sumologic.yaml.tmpl
      git commit -m "Generate new 'fluentd-sumologic.yaml.tmpl'"
      git push --quiet origin-repo "${branch}"
  else
      echo "No changes in 'fluentd-sumologic.yaml.tmpl'."
  fi

  echo "Generating setup job yaml from helm chart..."
  echo "# This file is auto-generated." > deploy/kubernetes/setup-sumologic.yaml.tmpl

  # Get list of templates available for default values.yaml
  with_files=$(find deploy/helm/sumologic/templates/setup -maxdepth 1 -iname "*.yaml" ! -path "*/setup-scc.yaml" | sed 's#deploy/helm/sumologic/templates#-s templates#g' | sed 's/yaml/yaml /g')
  # shellcheck disable=SC2086
  helm template deploy/helm/sumologic \
    ${with_files} \
    --namespace "\$NAMESPACE" \
    --name-template collection \
    --set dryRun=true >> deploy/kubernetes/setup-sumologic.yaml.tmpl 2>/dev/null \
    --set sumologic.accessId="\$SUMOLOGIC_ACCESSID" \
    --set sumologic.accessKey="\$SUMOLOGIC_ACCESSKEY" \
    --set sumologic.collectorName="\$COLLECTOR_NAME" \
    --set sumologic.clusterName="\$CLUSTER_NAME"

  if [[ -n $(git diff deploy/kubernetes/setup-sumologic.yaml.tmpl) ]]; then
      echo "Detected changes in 'setup-sumologic.yaml.tmpl', committing the updated version to ${branch}..."
      git add deploy/kubernetes/setup-sumologic.yaml.tmpl
      git commit -m "Generate new 'setup-sumologic.yaml.tmpl'"
      git push --quiet origin-repo "${branch}"
  else
      echo "No changes in 'setup-sumologic.yaml.tmpl'."
  fi

  # Generate override yaml files for chart dependencies to determine if changes are made to overrides yaml files
  echo "Generating overrides files..."
  
  echo "Copy metrics-server section from 'values.yaml'  to 'metrics-server-overrides.yaml'"
  echo "# This file is auto-generated." > deploy/helm/metrics-server-overrides.yaml
  # Copy lines of metrics_server section and remove indention from values.yaml
  yq r deploy/helm/sumologic/values.yaml metrics-server | yq d - enabled >> deploy/helm/metrics-server-overrides.yaml
  
  echo "Copy  fluent-bit section from 'values.yaml' to 'fluent-bit-overrides.yaml'"
  echo "# This file is auto-generated." > deploy/helm/fluent-bit-overrides.yaml
  # Copy lines of fluent-bit section and remove indention from values.yaml
  yq r deploy/helm/sumologic/values.yaml fluent-bit | yq d - enabled >> deploy/helm/fluent-bit-overrides.yaml
  
  echo "Copy prometheus-operator section from 'values.yaml' to  'prometheus-overrides.yaml'"
  echo "# This file is auto-generated." > deploy/helm/prometheus-overrides.yaml
  # Copy lines of prometheus-operator section and remove indention from values.yaml
  yq r deploy/helm/sumologic/values.yaml prometheus-operator >> deploy/helm/prometheus-overrides.yaml

  echo "Copy prometheus.prometheusSpec.remoteWrite from 'prometheus-overrides.yaml' and inject into 'deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet'"
  prometheus_remote_write=$(yq r deploy/helm/prometheus-overrides.yaml prometheus.prometheusSpec.remoteWrite -j | jq '.' | sed 's/^/    /')
  # Escaping so sed will work
  prometheus_remote_write="${prometheus_remote_write//\\/\\\\}"
  prometheus_remote_write="${prometheus_remote_write//\//\\/}"
  prometheus_remote_write="${prometheus_remote_write//&/\\&}"
  prometheus_remote_write="${prometheus_remote_write//$'\n'/\\n}"
  echo "// This file is autogenerated" > deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet
  # shellcheck disable=SC2016
  sed "s#\[\/\*REMOTE_WRITE\*\/\]#${prometheus_remote_write}#" ci/jsonnet-mixin.tmpl \
    | sed 's#"http://$(CHART).$(NAMESPACE).svc.cluster.local:9888\/#$._config.sumologicCollectorSvc + "#g' \
    | sed 's/+:     /+: /' \
    | sed -r 's/"(\w*)":/\1:/g' > deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet
  
  echo "Copy falco section from 'values.yaml' to 'falco-overrides.yaml'"
  echo "# This file is auto-generated." > deploy/helm/falco-overrides.yaml
  # Copy lines of falco section and remove indention from values.yaml
  yq r deploy/helm/sumologic/values.yaml falco | yq d - enabled >> deploy/helm/falco-overrides.yaml

  if [ -n "$(git diff deploy/helm/metrics-server-overrides.yaml)" ] || [ -n "$(git diff deploy/helm/fluent-bit-overrides.yaml)" ] || [ -n "$(git diff deploy/helm/prometheus-overrides.yaml)" ] || [ -n "$(git diff deploy/helm/falco-overrides.yaml)" ] || [ -n "$(git diff deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet)" ]; then
    echo "Detected changes in 'fluent-bit-overrides.yaml', 'prometheus-overrides.yaml', 'falco-overrides.yaml', or 'kube-prometheus-sumo-logic-mixin.libsonnet', committing the updated version to ${TRAVIS_PULL_REQUEST_BRANCH}..."
    git add deploy/helm/*-overrides.yaml
    git add deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet
    git commit -m "Generate new overrides yaml/libsonnet file(s)."
    git push --quiet origin-repo "${branch}"
  else
    echo "No changes in the generated overrides files."
  fi
}

# Set up Github
if [ -n "${GITHUB_TOKEN}" ]; then
  set_up_github "${GITHUB_TOKEN}" "$(get_branch_to_checkout)"
fi

# Check for invalid changes to generated yaml files (non-Tag builds)
# Exclude branches that start with "revert-" to allow reverts
if [ -n "${GITHUB_TOKEN}" ] && [ "${TRAVIS_EVENT_TYPE}" == "pull_request" ] && [[ ! "${TRAVIS_PULL_REQUEST_BRANCH}" =~ ^revert- ]]; then
  validate_changes_to_generated_files || (echo "Aborting due to manual changes detected in generated files" && exit 1)
fi

bundle_fluentd_plugins "${VERSION}" || (echo "Failed bundling fluentd plugins" && exit 1)
build_docker_image "${DOCKER_TAG}" || (echo "Error during building docker image" && exit 1)

# Check for changes that require re-generating overrides yaml files
if [ -n "${GITHUB_TOKEN}" ] && [ "${TRAVIS_EVENT_TYPE}" == "pull_request" ]; then
  generate_overrides "${TRAVIS_PULL_REQUEST_BRANCH}" || (echo "Error generating override files" && exit 1)
fi

if [ -n "${DOCKER_PASSWORD}" ] && [ -n "${TRAVIS_TAG}" ]; then
  push_docker_image "${VERSION}"
  push_helm_chart "${VERSION}"

elif [ -n "${DOCKER_PASSWORD}" ] && [[ "${TRAVIS_BRANCH}" == "master" || "${TRAVIS_BRANCH}" =~ ^release-v[0-9]+\.[0-9]+$ ]] && [ "${TRAVIS_EVENT_TYPE}" == "push" ]; then
  dev_build_tag=$(git describe --tags --always)
  dev_build_tag=${dev_build_tag#v}
  push_docker_image "${dev_build_tag}"
  push_helm_chart "${dev_build_tag}"

else
  echo "Skip Docker pushing"
fi

echo "DONE"
