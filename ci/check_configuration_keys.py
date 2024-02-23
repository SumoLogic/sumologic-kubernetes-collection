#!/usr/bin/env python3
"""Prints differences between values.yaml and README.md configuration keys
"""

import argparse
import json
import re
import sys

import yaml
from yaml.loader import SafeLoader

DESCRIPTION = 'This program verifies if all configuration from values.yaml has been documented.'
SKIP_DEFAULTS = {
    'kube-prometheus-stack.enabled',
    'kube-prometheus-stack.global.imagePullSecrets',
    'metadata.logs.autoscaling.targetMemoryUtilizationPercentage',
    'metadata.logs.podDisruptionBudget',
    'metadata.logs.statefulset.extraEnvVars',
    'metadata.logs.statefulset.extraVolumeMounts',
    'metadata.logs.statefulset.extraVolumes',
    'metadata.logs.statefulset.extraPorts',
    'metadata.metrics.podDisruptionBudget',
    'metadata.metrics.autoscaling.targetMemoryUtilizationPercentage',
    'metadata.metrics.statefulset.extraEnvVars',
    'metadata.metrics.statefulset.extraVolumeMounts',
    'metadata.metrics.statefulset.extraVolumes',
    'metadata.persistence.storageClass',
    'opentelemetry-operator.instrumentation.dotnet.extraEnvVars',
    'opentelemetry-operator.instrumentation.java.extraEnvVars',
    'opentelemetry-operator.instrumentation.python.extraEnvVars',
    'opentelemetry-operator.instrumentation.nodejs.extraEnvVars',
    'otelcolInstrumentation.statefulset.priorityClassName',
    'otelcolInstrumentation.statefulset.extraEnvVars',
    'otelcolInstrumentation.statefulset.extraVolumeMounts',
    'otelcolInstrumentation.statefulset.extraVolumes',
    'tracesGateway.deployment.extraEnvVars',
    'tracesGateway.deployment.extraVolumeMounts',
    'tracesGateway.deployment.extraVolumes',
    'tracesSampler.deployment.extraEnvVars',
    'tracesSampler.deployment.extraVolumeMounts',
    'tracesSampler.deployment.extraVolumes',
    'sumologic.setup.job.tolerations',
    'sumologic.setup.job.pullSecrets',
    'sumologic.pullSecrets',
    'sumologic.setup.force',
    'sumologic.setup.debug',
    'metrics-server.image.pullSecrets',
    'sumologic.events.sourceCategory',
}

def main(values_path: str, readme_path: str, full_diff=False) -> None:
    """Prints differences between configuration keys from values_path and readme_path

    Args:
        values_path (str): path to values.yaml
        readme_path (str): path to README.md
    """
    values = values_to_dictionary(values_path)
    values_keys = extract_keys(values)
    readme = extract_keys_from_readme(readme_path)

    values_distinct = compare_list_of_keys(values_keys, readme.keys())
    readme_distinct = compare_list_of_keys(readme.keys(), values_keys)
    diff_defaults = compare_values(readme, values_keys, values)

    if values_distinct:
        print('*' * 20)
        print(f'Keys in values not covered by readme ({len(values_distinct)}):')
        print('*' * 20)
        for key in values_distinct:
            print(key)

    if readme_distinct:
        print('*' * 20)
        print(f'Keys in readme not existing in values ({len(readme_distinct)}):')
        print('*' * 20)
        for key in readme_distinct:
            print(key)

    if diff_defaults:
        max_key_length = max(len(key) for key in diff_defaults)

        print('*' * 20)
        print(f'Default values comparison ({len(diff_defaults)}):')
        print('*' * 20)

        if full_diff:
            for key in sorted(diff_defaults.keys()):
                readme_value, values_value = diff_defaults[key]
                print(f'| {key:{max_key_length}} | {readme_value} | {values_value} |')
        else:
            print(f'| {"Key":{max_key_length}} | {"Default for readme":100} |'
                  f'{"Default for values":100} |')
            print(f'|{"-"*(max_key_length+2)}|{"-"*102}|{"-"*102}|')

            for key in sorted(diff_defaults.keys()):
                readme_value, values_value = diff_defaults[key]

                # Show only first 100 characters of every default
                print(f'| {key:{max_key_length}} | {readme_value[:100]:100} |'
                      f'{values_value[:100]:100} |')

    if values_distinct or readme_distinct or diff_defaults:
        sys.exit(1)


def values_to_dictionary(path: str) -> dict:
    """Reads given path as values.yaml and returns it as dict

    Args:
        path (str): path to the value.yaml

    Returns:
        dict: values.yaml as dict
    """
    with open(path, encoding='utf-8') as file:
        values_yaml = file.read()
        values_yaml = re.sub(r'(\[\]|\{\})\n(\s+# )', r'\n\2', values_yaml, flags=re.M)
        values_yaml = re.sub(r'^(\s+)# ', r'\1', values_yaml, flags=re.M)
        return yaml.load(values_yaml, Loader=SafeLoader)


def extract_keys_from_readme(path: str) -> dict:
    """Reads given path as README.md and returns dict in the following form:

    ```
    {
        configuration_key: configuration_default
    }
    ```

    Args:
        path (str): path to the README.md

    Returns:
        dict: {configuration_key: configuration_default,...}
    """
    with open(path, encoding='utf-8') as file:
        readme = file.readlines()

    keys = {}

    for line in readme:
        match = re.match(
            r'^\|\s+`(?P<key>.*?)`\s+\|\s+(?P<description>.*?)\s+\|\s+(?P<value>.*?)\s+\|$',
            line)
        if match and match.group('key'):
            value = match.group('value').strip('`').strip('"')
            keys[match.group('key')] = value
        elif line.startswith('|') and not line[:5] in {'| ---', '| Par'}:
            print(line)

    return keys


def extract_keys(dictionary: dict) -> list:
    """Extracts list of keys from the dictionary and returns as list.
    Uses dot as separator for nested dicts.

    Args:
        dictionary (dict): dictionary to extract keys from

    Returns:
        list: list of extracted keys
    """
    keys = []
    if not isinstance(dictionary, dict):
        return None

    if not dictionary:
        return None

    for key, value in dictionary.items():
        more_keys = extract_keys(value)

        if more_keys is None:
            keys.append(key)
        else:
            keys.extend(f'{key}.{mk}' for mk in more_keys)

    return keys


def compare_keys(this: str, other: str) -> bool:
    """Compares this and other and returns true if any of arguments begins with other.

    Args:
        this (str): string to compare
        other (str): string to compare

    Returns:
        bool: _description_
    """
    return this.startswith(other) or other.startswith(this)


def compare_list_of_keys(this: list[str], other: list[str]) -> list:
    """Returns all elements from this which are not beginning of any element of other

    Args:
        this (list[str]): list of elements to check
        other (list[str]): list of elements to check against

    Returns:
        list[str]: all elements from this which are not beginning of any element of other
    """
    diff = []

    for this_key in this:
        found = False
        for other_key in other:
            if compare_keys(this_key, other_key):
                found = True
                break
        if not found:
            diff.append(this_key)

    return sorted(diff)


def compare_values(readme: dict, values_keys: list[str], values: dict) -> dict:
    """Returns dictionary in the following form:

    ```
    {
        readme_key: [readme_default, values_default]
    }
    ```

    Args:
        readme (dict): dictionary representing readme
        values_keys (list[str]): dot separated values keys
        values_keys (dict): values

    Returns:
        dict:     {readme_key: [readme_default, values_default,...}
    """
    diff = {}
    for this_key, this_value in readme.items():
        if this_key in SKIP_DEFAULTS:
            continue

        for other_key in values_keys:
            if compare_keys(this_key, other_key):
                other_value = get_value(this_key, values)
                if this_value != other_value:

                    # Skip configuration linked to values.yaml
                    if this_value == 'See [values.yaml]':
                        continue

                    # ToDo: compare types
                    if this_value in {'Nil', '{}'} and other_value in {'', 'null'}:
                        break
                    diff[f'{this_key}'] = [this_value, other_value]

    return diff


def get_value(key: str, dictionary: dict) -> str:
    """Returns value from dictionary for dot separated key

    Args:
        key (str): dot separated key
        dictionary (dict): dictionary to get values from

    Returns:
        str: value for the given key. This is string or dumped json
    """
    value = dictionary

    for subkey in key.split('.'):
        value = value[subkey]

    if isinstance(value, str):
        return value

    return json.dumps(value)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog = sys.argv[0],
        description = DESCRIPTION)
    parser.add_argument('--values', required=True)
    parser.add_argument('--readme', required=True)
    parser.add_argument('--full-diff', required=False, action='store_true')
    args = parser.parse_args()

    main(args.values, args.readme, args.full_diff)
