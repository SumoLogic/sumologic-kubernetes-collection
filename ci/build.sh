#!/bin/sh

if [ -n "$TRAVIS_COMMIT_RANGE" ] && [ "$TRAVIS_PULL_REQUEST" == false ]; then
  if git diff --name-only $TRAVIS_COMMIT_RANGE | grep -q -i "fluentd-sumologic.yaml.tmpl"; then
    if git --no-pager show -s --format="%an" . | grep -v -q -i "travis"; then
      echo "Detected manual changes in 'fluentd-sumologic.yaml.tmpl', abort."
      exit 1
    fi
  fi
fi

VERSION="${TRAVIS_TAG:-0.0.0}"
VERSION="${VERSION#v}"
: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"
: "${DOCKER_USERNAME:=sumodocker}"
DOCKER_TAGS="https://registry.hub.docker.com/v1/repositories/sumologic/kubernetes-fluentd/tags"

echo "Starting build process in: `pwd` with version tag: $VERSION"
set -e

for i in ./fluent-plugin* ; do
  if [ -d "$i" ]; then
    cd $i
    PLUGIN_NAME=$(basename "$i")
    # Strip "-alpha" suffix if it exists to avoid gem prerelease behavior
    GEM_VERSION=${VERSION%"-alpha"}
    echo "Building gem $PLUGIN_NAME version $GEM_VERSION in `pwd` ..."
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

echo "Building docker image with $DOCKER_TAG:local in `pwd`..."
cd ./deploy/docker
docker build . -f ./Dockerfile -t $DOCKER_TAG:local --no-cache
rm -f ./gems/*.gem
cd ../..

echo "Test docker image locally..."
ruby deploy/test/test_docker.rb

if [ "$TRAVIS_BRANCH" != "master" ] && [ "$TRAVIS_EVENT_TYPE" == "push" ] && [ -n "$GITHUB_TOKEN" ]; then
  echo "Generating yaml from helm chart..."
  echo "# This file is auto-generated." > deploy/kubernetes/fluentd-sumologic.yaml.tmpl
  sudo helm template deploy/helm/sumologic --namespace "\$NAMESPACE" --set dryRun=true >> deploy/kubernetes/fluentd-sumologic.yaml.tmpl

  if [[ $(git diff deploy/kubernetes/fluentd-sumologic.yaml.tmpl) ]]; then
      echo "Detected changes in 'fluentd-sumologic.yaml.tmpl', committing the updated version to $TRAVIS_BRANCH..."
      git config --global user.email "travis@travis-ci.org"
      git config --global user.name "Travis CI"
      git remote add origin-repo https://${GITHUB_TOKEN}@github.com/SumoLogic/sumologic-kubernetes-collection.git > /dev/null 2>&1
      git fetch origin-repo
      git checkout $TRAVIS_BRANCH
      git add deploy/kubernetes/fluentd-sumologic.yaml.tmpl
      git commit -m "Generate new 'fluentd-sumologic.yaml.tmpl'"
      git push --quiet origin-repo "$TRAVIS_BRANCH"
  else
      echo "No changes in 'fluentd-sumologic.yaml.tmpl'."
  fi

  # Push new helm release
  sudo helm package deploy/helm/sumologic --version=$VERSION
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
  git remote add origin-repo https://${GITHUB_TOKEN}@github.com/SumoLogic/sumologic-kubernetes-collection.git > /dev/null 2>&1
  git fetch origin-repo
  git checkout gh-pages
  sudo helm repo index ./ --url https://sumologic.github.io/sumologic-kubernetes-collection/
  git commit -a -m "Push new Helm Chart release $VERSION"
  git push --quiet origin-repo gh-pages
fi

if [ -n "$DOCKER_PASSWORD" ] && [ -n "$TRAVIS_TAG" ] && [[ $TRAVIS_TAG != *alpha* ]]; then
  echo "Tagging docker image $DOCKER_TAG:local with $DOCKER_TAG:$VERSION..."
  docker tag $DOCKER_TAG:local $DOCKER_TAG:$VERSION
  echo "Pushing docker image $DOCKER_TAG:$VERSION..."
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  docker push $DOCKER_TAG:$VERSION


elif [ -n "$DOCKER_PASSWORD" ] && [ "$TRAVIS_BRANCH" == "master" ] && [ "$TRAVIS_EVENT_TYPE" == "push" ]; then
  # Major.minor.patch version format
  latest_release=`wget -q $DOCKER_TAGS -O - | jq -r .[].name | grep -v alpha | grep -v latest | sort --version-sort --field-separator=. | tail -1`
  latest_major=`echo $latest_release | tr '.' $'\n' | sed -n 1p`
  latest_minor=`echo $latest_release | tr '.' $'\n' | sed -n 2p`
  latest_alpha=`wget -q $DOCKER_TAGS -O - | jq -r .[].name | grep alpha | grep "^$latest_major.$latest_minor" | sed 's/-alpha//g' | sort --version-sort --field-separator=. | tail -1`
  if [ -n "$latest_alpha" ]; then
    echo "Most recent release version: $latest_release, most recent alpha: $latest_alpha-alpha"
  else
    echo "Most recent release version: $latest_release, most recent alpha does not yet exist"
    latest_alpha="$latest_release"
  fi
  new_patch=$((`echo $latest_alpha | tr '.' $'\n' | sed -n 3p`+1))
  new_alpha="$latest_major.$latest_minor.$new_patch-alpha"
  
  echo "Tagging docker image $DOCKER_TAG:local with $DOCKER_TAG:$new_alpha..."
  docker tag $DOCKER_TAG:local $DOCKER_TAG:$new_alpha
  echo "Pushing alpha docker image with version $new_alpha"
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  docker push $DOCKER_TAG:$new_alpha

  echo "Tagging git with v$new_alpha..."
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
  git remote add origin-repo https://${GITHUB_TOKEN}@github.com/SumoLogic/sumologic-kubernetes-collection.git > /dev/null 2>&1
  git tag -a "v$new_alpha" -m "Bump version to v$new_alpha"
  git push --tags --quiet --set-upstream origin-repo master
else
  echo "Skip Docker pushing"
fi

echo "DONE"
