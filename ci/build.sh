#!/bin/bash

VERSION="${TRAVIS_TAG:-0.0.0}"
VERSION="${VERSION#v}"
: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"
: "${DOCKER_USERNAME:=sumodocker}"
DOCKER_TAGS="https://registry.hub.docker.com/v1/repositories/sumologic/kubernetes-fluentd/tags"

echo "Starting build process in: $(pwd) with version tag: $VERSION"
err_report() {
    echo "Script error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

# Set up Github
if [ -n "$GITHUB_TOKEN" ]; then
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
  git remote add origin-repo https://${GITHUB_TOKEN}@github.com/SumoLogic/sumologic-kubernetes-collection.git > /dev/null 2>&1
  git fetch origin-repo
  git checkout $TRAVIS_PULL_REQUEST_BRANCH
fi

# Check for invalid changes to generated yaml files (non-Tag builds)
if [ -n "$GITHUB_TOKEN" ] && [ "$TRAVIS_EVENT_TYPE" == "pull_request" ]; then
  # Check most recent commit author. If non-Travis, check for changes made to generated files
  recent_author=$(git log origin-repo/master..HEAD --format="%an" | grep -m1 "")
  if echo $recent_author | grep -v -q -i "travis"; then
    # NOTE(ryan, 2019-08-30): Append "|| true" to command to ignore non-zero exit code
    changes=$(git log origin-repo/master..HEAD --name-only --format="" --author="$recent_author" | grep -i "fluentd-sumologic.yaml.tmpl\|fluent-bit-overrides.yaml\|prometheus-overrides.yaml\|falco-overrides.yaml") || true
    if [ -n "$changes" ]; then
      echo "Aborting due to manual changes detected in the following generated files: $changes"
      exit 1
    fi
  fi
fi

for i in ./fluent-plugin* ; do
  if [ -d "$i" ]; then
    cd $i
    PLUGIN_NAME=$(basename "$i")
    # Strip "-alpha" suffix if it exists to avoid gem prerelease behavior
    GEM_VERSION=${VERSION%"-alpha"}
    echo "Building gem $PLUGIN_NAME version $GEM_VERSION in $(pwd) ..."
    sed -i.bak "s/0.0.0/$GEM_VERSION/g" ./$PLUGIN_NAME.gemspec
    rm -f ./$PLUGIN_NAME.gemspec.bak

    echo "Install bundler..."
    bundle install

    echo "Run unit tests..."
    bundle exec rake

    echo "Build gem $PLUGIN_NAME $GEM_VERSION..."
    gem build $PLUGIN_NAME
    mv *.gem ../deploy/docker/gems

    cd ..
  fi
done

echo "Building docker image with $DOCKER_TAG:local in $(pwd)..."
cd ./deploy/docker
docker build . -f ./Dockerfile -t $DOCKER_TAG:local --no-cache
rm -f ./gems/*.gem
cd ../..

echo "Test docker image locally..."
ruby deploy/test/test_docker.rb

# Check for changes that require re-generating overrides yaml files
if [ -n "$GITHUB_TOKEN" ] && [ "$TRAVIS_EVENT_TYPE" == "pull_request" ]; then
  echo "Generating deployment yaml from helm chart..."
  echo "# This file is auto-generated." > deploy/kubernetes/fluentd-sumologic.yaml.tmpl
  sudo helm init --client-only
  cd deploy/helm/sumologic
  sudo helm dependency update
  cd ../../../

  # NOTE(ryan, 2019-11-06): helm template -execute is going away in Helm 3 so we will need to revisit this
  # https://github.com/helm/helm/issues/5887
  with_files=$(ls deploy/helm/sumologic/templates/*.yaml | sed 's#deploy/helm/sumologic/templates#-x templates#g' | sed 's/yaml/yaml \\\/g')
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

  with_files=$(ls deploy/helm/sumologic/templates/setup/*.yaml | sed 's#deploy/helm/sumologic/templates#-x templates#g' | sed 's/yaml/yaml \\\/g')
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
  sed "s#\[\/\*REMOTE_WRITE\*\/\]#$prometheus_remote_write#" ci/jsonnet-mixin.tmpl | sed 's#"http://collection-sumologic.sumologic.svc.cluster.local:9888\/#$._config.sumologicCollectorSvc + "#g' | sed 's/+:     /+: /' | sed -r 's/"(\w*)":/\1:/g' > deploy/kubernetes/kube-prometheus-sumo-logic-mixin.libsonnet
  
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

if [ -n "$DOCKER_PASSWORD" ] && [ -n "$TRAVIS_TAG" ] && [[ $TRAVIS_TAG != *alpha* ]]; then
  echo "Tagging docker image $DOCKER_TAG:local with $DOCKER_TAG:$VERSION..."
  docker tag $DOCKER_TAG:local $DOCKER_TAG:$VERSION
  echo "Pushing docker image $DOCKER_TAG:$VERSION..."
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  docker push $DOCKER_TAG:$VERSION

  # Push new helm release
  echo "Pushing new Helm Chart release $VERSION"
  git checkout -- .
  sudo helm init --client-only
  sudo helm package deploy/helm/sumologic --dependency-update --version=$VERSION --app-version=$VERSION
  git fetch origin-repo
  git checkout gh-pages
  sudo helm repo index ./ --url https://sumologic.github.io/sumologic-kubernetes-collection/
  git add -A
  git commit -m "Push new Helm Chart release $VERSION"
  git push --quiet origin-repo gh-pages

elif [ -n "$DOCKER_PASSWORD" ] && [ "$TRAVIS_BRANCH" == "master" ] && [ "$TRAVIS_EVENT_TYPE" == "push" ]; then
  # Major.minor.patch version format
  latest_release=$(wget -q $DOCKER_TAGS -O - | jq -r .[].name | grep -v alpha | grep -v latest | sort --version-sort --field-separator=. | tail -1)
  latest_major=$(echo $latest_release | tr '.' $'\n' | sed -n 1p)
  latest_minor=$(echo $latest_release | tr '.' $'\n' | sed -n 2p)
  latest_alpha=$(wget -q $DOCKER_TAGS -O - | jq -r .[].name | grep alpha | grep "^$latest_major.$latest_minor" | sed 's/-alpha//g' | sort --version-sort --field-separator=. | tail -1)
  if [ -n "$latest_alpha" ]; then
    echo "Most recent release version: $latest_release, most recent alpha: $latest_alpha-alpha"
  else
    echo "Most recent release version: $latest_release, most recent alpha does not yet exist"
    latest_alpha="$latest_release"
  fi
  new_patch=$(($(echo $latest_alpha | tr '.' $'\n' | sed -n 3p)+1))
  new_alpha="$latest_major.$latest_minor.$new_patch-alpha"
  
  echo "Tagging docker image $DOCKER_TAG:local with $DOCKER_TAG:$new_alpha..."
  docker tag $DOCKER_TAG:local $DOCKER_TAG:$new_alpha
  echo "Pushing alpha docker image with version $new_alpha"
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  docker push $DOCKER_TAG:$new_alpha

  echo "Tagging git with v$new_alpha..."
  git tag -a "v$new_alpha" -m "Bump version to v$new_alpha"
  git push --tags --quiet --set-upstream origin-repo master

  # Push new alpha helm release
  echo "Pushing new alpha Helm Chart release $new_alpha"
  git checkout -- .
  sudo helm init --client-only
  sudo helm package deploy/helm/sumologic --dependency-update --version=$new_alpha --app-version=$new_alpha
  git fetch origin-repo
  git checkout gh-pages
  sudo helm repo index ./ --url https://sumologic.github.io/sumologic-kubernetes-collection/
  git add -A
  git commit -m "Push new alpha Helm Chart release $new_alpha"
  git push --quiet origin-repo gh-pages
else
  echo "Skip Docker pushing"
fi

echo "DONE"
