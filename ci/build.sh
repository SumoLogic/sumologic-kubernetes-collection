#!/bin/sh

VERSION="${TRAVIS_TAG:-0.0.0}"
VERSION="${VERSION#v}"
: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"
: "${DOCKER_USERNAME:=sumodocker}"

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

echo "Building docker image with $DOCKER_TAG:$VERSION in `pwd`..."
cd ./deploy/docker
docker build . -f ./Dockerfile -t $DOCKER_TAG:$VERSION --no-cache
rm -f ./gems/*.gem
cd ../..

echo "Test docker image locally..."
ruby deploy/test/test_docker.rb

if [ -z "$DOCKER_PASSWORD" ] || [ -z "$TRAVIS_TAG" ]; then
    echo "Skip Docker pushing"
else
    echo "Pushing docker image with $DOCKER_TAG:$VERSION ..."
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker push $DOCKER_TAG:$VERSION
fi

echo "DONE"
