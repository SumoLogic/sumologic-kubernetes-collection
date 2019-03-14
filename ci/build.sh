#!/bin/sh

VERSION="${TRAVIS_TAG:=0.0.0}"
DOCKER_TAG="sumologic/kubernetes-collection"

echo "Starting build process in: `pwd` with version tag: $VERSION"
set -e

for i in ./fluent-plugin* ; do
  if [ -d "$i" ]; then
    pushd $i > /dev/null
    PLUGIN_NAME=$(basename "$i")
    
    echo "Building gems $PLUGIN_NAME in `pwd` ..."
    sed -i.bak "s/0.0.0/$VERSION/g" ./$PLUGIN_NAME.gemspec
    rm -f ./$PLUGIN_NAME.gemspec.bak
    
    echo "Install bundler..."
    bundle install
    
    echo "Run unit tests..."
    bundle exec rake

    echo "Build gem $PLUGIN_NAME $VERSION..."
    gem build $PLUGIN_NAME
    mv *.gem ../deploy/docker/gems
    
    popd > /dev/null
  fi
done

echo "Building docker image with $DOCKER_TAG:$VERSION in `pwd`..."
pushd ./deploy/docker > /dev/null
docker build . -f ./Dockerfile -t $DOCKER_TAG:$VERSION --no-cache
rm -f ./gems/*.gem
popd > /dev/null

echo "DONE"
