#!/usr/bin/env bash

function test_fluentd_plugin() {
  local plugin_name="${1}"
  local version="${2}"
  # Strip everything after "-" (longest match) to avoid gem prerelease behavior
  local gem_version="${version%%-*}"
  local result

  pushd "${plugin_name}" || exit 1

  if [[ -z "${version}" ]] ; then
    echo "Please provide the version when bundling fluentd plugins"
    exit 1
  fi

  echo "Preparing gem ${plugin_name} version ${gem_version} in $(pwd) for testing ..."
  sed -i.bak "s/0.0.0/${gem_version}/g" ./"${plugin_name}".gemspec
  rm -f ./"${plugin_name}".gemspec.bak

  echo "Install bundler..."
  bundle install

  echo "Run unit tests..."
  bundle exec rake

  readonly result=$?
  popd || exit 1
  if [ "${result}" -ne "0" ]; then
   exit 1
  fi
}

function test_fluentd_plugins() {
  local version="${1}"

  if [[ -z "${version}" ]] ; then
    echo "Please provide the version when bundling fluentd plugins"
    exit 1
  fi

  find . -maxdepth 1 -name 'fluent-plugin-*' -type 'd' -print |
    while read -r line; do
      # Run tests in their own context
      test_fluentd_plugin "$(basename "${line}")" "${version}" || exit 1
    done
}
