#!/bin/bash

VERSION="${TRAVIS_TAG:-0.0.0}"
VERSION="${VERSION#v}"

echo "Starting build process in: $(pwd) with version tag: ${VERSION}"
err_report() {
    echo "Script error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

function get_branch_to_checkout() {
  [[ "${TRAVIS_EVENT_TYPE}" == pull_request ]] \
    && echo "${TRAVIS_PULL_REQUEST_BRANCH}" \
    || echo "${TRAVIS_BRANCH}"
}

# Set up Github
if [ -n "$GITHUB_TOKEN" ]; then
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
  git remote add origin-repo "https://${GITHUB_TOKEN}@github.com/SumoLogic/sumologic-kubernetes-collection.git" > /dev/null 2>&1
  git fetch --unshallow origin-repo

  readonly branch_to_checkout="$(get_branch_to_checkout)"
  echo "Checking out the ${branch_to_checkout} branch..."
  git checkout "${branch_to_checkout}"
fi

# Check for invalid changes to generated yaml files (non-Tag builds)
# Exclude branches that start with "revert-" to allow reverts
if [ -n "$GITHUB_TOKEN" ] && [ "$TRAVIS_EVENT_TYPE" == "pull_request" ] && [[ ! "$TRAVIS_PULL_REQUEST_BRANCH" =~ ^revert- ]]; then
  # Check most recent commit author. If non-Travis, check for changes made to generated files
  recent_author=$(git log origin-repo/master..HEAD --format="%an" | grep -m1 "")
  if echo "$recent_author" | grep -v -q -i "travis"; then
    # NOTE(ryan, 2019-08-30): Append "|| true" to command to ignore non-zero exit code
    changes=$(git log origin-repo/master..HEAD --name-only --format="" --author="$recent_author" | grep -i "fluentd-sumologic.yaml.tmpl\|fluent-bit-overrides.yaml\|prometheus-overrides.yaml\|falco-overrides.yaml") || true
    if [ -n "$changes" ]; then
      echo "Aborting due to manual changes detected in the following generated files: $changes"
      exit 1
    fi
  fi
fi

# Test if template files are generated correctly for various values.yaml
echo "Test helm templates generation"
if ./tests/run.sh; then
  echo "Helm templates generation test passed"
else
  echo "Tracing templates generation test failed"
  exit 1
fi

# Check for changes that require re-generating overrides yaml files
if [ -n "$GITHUB_TOKEN" ] && [ "$TRAVIS_EVENT_TYPE" == "pull_request" ]; then
  echo "Generating deployment yaml from helm chart..."
  echo "# This file is auto-generated." > deploy/kubernetes/fluentd-sumologic.yaml.tmpl
  sudo helm init --client-only
  sudo helm repo add falcosecurity https://falcosecurity.github.io/charts
  sudo helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  cd deploy/helm/sumologic || exit 1
  sudo helm dependency update
  cd ../../../ || exit 1

  # NOTE(ryan, 2019-11-06): helm template -execute is going away in Helm 3 so we will need to revisit this
  # https://github.com/helm/helm/issues/5887
  with_files=$(find deploy/helm/sumologic/templates/ -maxdepth 1 -iname "*.yaml" | sed 's#deploy/helm/sumologic/templates#-x templates#g' | sed 's/yaml/yaml \\/g')
  eval 'sudo helm template deploy/helm/sumologic $with_files --namespace "\$NAMESPACE" --name collection --set dryRun=true >> deploy/kubernetes/fluentd-sumologic.yaml.tmpl --set sumologic.endpoint="bogus" --set sumologic.accessId="bogus" --set sumologic.accessKey="bogus"'

  if [[ $(git diff deploy/kubernetes/fluentd-sumologic.yaml.tmpl) ]]; then
      echo "Detected changes in 'fluentd-sumologic.yaml.tmpl', committing the updated version to $TRAVIS_PULL_REQUEST_BRANCH..."
      git add deploy/kubernetes/fluentd-sumologic.yaml.tmpl
      git commit -m "Generate new 'fluentd-sumologic.yaml.tmpl'"
      git push --quiet origin-repo "$TRAVIS_PULL_REQUEST_BRANCH"
  else
      echo "No changes in 'fluentd-sumologic.yaml.tmpl'."
  fi

  echo "Generating setup job yaml from helm chart..."
  echo "# This file is auto-generated." > deploy/kubernetes/setup-sumologic.yaml.tmpl

  with_files=$(find deploy/helm/sumologic/templates/setup/ -maxdepth 1 -iname "*.yaml" | sed 's#deploy/helm/sumologic/templates#-x templates#g' | sed 's/yaml/yaml \\/g')
  eval 'sudo helm template deploy/helm/sumologic $with_files --namespace "\$NAMESPACE" --name collection --set dryRun=true >> deploy/kubernetes/setup-sumologic.yaml.tmpl --set sumologic.accessId="\$SUMOLOGIC_ACCESSID" --set sumologic.accessKey="\$SUMOLOGIC_ACCESSKEY" --set sumologic.collectorName="\$COLLECTOR_NAME" --set sumologic.clusterName="\$CLUSTER_NAME"'
  if [[ $(git diff deploy/kubernetes/setup-sumologic.yaml.tmpl) ]]; then
      echo "Detected changes in 'setup-sumologic.yaml.tmpl', committing the updated version to $TRAVIS_PULL_REQUEST_BRANCH..."
      git add deploy/kubernetes/setup-sumologic.yaml.tmpl
      git commit -m "Generate new 'setup-sumologic.yaml.tmpl'"
      git push --quiet origin-repo "$TRAVIS_PULL_REQUEST_BRANCH"
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
  sed "s#\[\/\*REMOTE_WRITE\*\/\]#$prometheus_remote_write#" ci/jsonnet-mixin.tmpl | sed 's#"http://$(CHART).$(NAMESPACE).svc.cluster.local:9888\/#$._config.sumologicCollectorSvc + "#g' | sed 's/+:     /+: /' | sed -r 's/"(\w*)":/\1:/g' > deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet
  
  echo "Copy falco section from 'values.yaml' to 'falco-overrides.yaml'"
  echo "# This file is auto-generated." > deploy/helm/falco-overrides.yaml
  # Copy lines of falco section and remove indention from values.yaml
  yq r deploy/helm/sumologic/values.yaml falco | yq d - enabled >> deploy/helm/falco-overrides.yaml

  if [ "$(git diff deploy/helm/metrics-server-overrides.yaml)" ] || [ "$(git diff deploy/helm/fluent-bit-overrides.yaml)" ] || [ "$(git diff deploy/helm/prometheus-overrides.yaml)" ] || [ "$(git diff deploy/helm/falco-overrides.yaml)" ] || [ "$(git diff deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet)" ]; then
    echo "Detected changes in 'fluent-bit-overrides.yaml', 'prometheus-overrides.yaml', 'falco-overrides.yaml', or 'kube-prometheus-sumo-logic-mixin.libsonnet', committing the updated version to $TRAVIS_PULL_REQUEST_BRANCH..."
    git add deploy/helm/*-overrides.yaml
    git add deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet
    git commit -m "Generate new overrides yaml/libsonnet file(s)."
    git push --quiet origin-repo "$TRAVIS_PULL_REQUEST_BRANCH"
  else
    echo "No changes in the generated overrides files."
  fi
fi

echo "DONE"
