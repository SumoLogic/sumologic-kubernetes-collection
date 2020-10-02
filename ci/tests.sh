#!/bin/bash

VERSION="${TRAVIS_TAG:-0.0.0}"
VERSION="${VERSION#v}"

function test_fluentd_plugins() {
  local version="${1}"

  if [[ "${version}" == "" ]] ; then
    echo "Please provide the version when bundling fluentd plugins"
    exit 1
  fi

  for i in ./fluent-plugin-*/ ; do
    if [[ -d "${i}" ]]; then
    (
      cd "${i}" || exit 1
      local plugin_name
      plugin_name="$(basename "${i}")"
      # Strip everything after "-" (longest match) to avoid gem prerelease behavior
      local gem_version="${version%%-*}"
      echo "Preparing gem ${plugin_name} version ${gem_version} in $(pwd) for testing ..."
      sed -i.bak "s/0.0.0/${gem_version}/g" ./"${plugin_name}".gemspec
      rm -f ./"${plugin_name}".gemspec.bak

      echo "Install bundler..."
      bundle install

      echo "Run unit tests..."
      bundle exec rake
    )
    fi
  done
}

## check the build script with shellcheck
## TODO: the "|| true" prevents the build from failing on shellcheck errors - to be removed
echo "Checking the build script with shellcheck..."
shellcheck ci/build.sh || true
shellcheck ci/run-tests.sh || true

# Test if template files are generated correctly for various values.yaml
echo "Test helm templates generation"
if ./tests/run.sh; then
  echo "Helm templates generation test passed"
else
  echo "Tracing templates generation test failed"
  exit 1
fi

# Test upgrade script
echo "Test upgrade script..."
if ./tests/upgrade_script/run.sh; then
  echo "Upgrade Script test passed"
else
  echo "Upgrade Script test failed"
  exit 1
fi

test_fluentd_plugins "${VERSION}" || (echo "Failed testing fluentd plugins" && exit 1)

echo "DONE"
