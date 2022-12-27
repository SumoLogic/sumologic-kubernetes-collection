#!/usr/bin/env python3
"""Prints differences between values.yaml and README.md configuration keys
"""

import argparse
import re
import sys

import yaml
from yaml.loader import SafeLoader

DESCRIPTION = 'This program verifies if all configuration from values.yaml has been documented.'


def main(values_path: str, readme_path: str) -> None:
    """Prints differences between configuration keys from values_path and readme_path

    Args:
        values_path (str): path to values.yaml
        readme_path (str): path to README.md
    """
    values_keys = extract_keys_from_values(values_path)
    readme_keys = extract_keys_from_readme(readme_path)

    values_distinct = compare_list_of_keys(values_keys, readme_keys)
    readme_distinct = compare_list_of_keys(readme_keys, values_keys)

    print('*' * 20)
    print('Keys in values not covered by readme:')
    print('*' * 20)
    for key in values_distinct:
        print(key)

    print('*' * 20)
    print('Keys in readme not existing in values:')
    print('*' * 20)
    for key in readme_distinct:
        print(key)

    if values_distinct:
        sys.exit(1)


def extract_keys_from_values(path: str) -> list:
    """Reads given path as values.yaml and returns list of configuration keys

    Args:
        path (str): path to the value.yaml

    Returns:
        list: list of configuration keys
    """
    with open(path, encoding='utf-8') as file:
        values_yaml = file.read()
        values_yaml = re.sub(r'(\[\]|\{\})\n(\s+# )', r'\n\2', values_yaml, flags=re.M)
        values_yaml = re.sub(r'^(\s+)# ', r'\1', values_yaml, flags=re.M)
        values_yaml = yaml.load(values_yaml, Loader=SafeLoader)
        return extract_keys(values_yaml)


def extract_keys_from_readme(path: str) -> list:
    """Reads given path as README.md and returns list of covered configuration keys

    Args:
        path (str): path to the README.md

    Returns:
        list: list of covered configuration keys
    """
    with open(path, encoding='utf-8') as file:
        readme = file.readlines()

    keys = []

    for line in readme:
        match = re.match(r'^\| `(?P<key>.*?)`', line)
        if match:
            keys.append(match.group('key'))

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


def compare_list_of_keys(this: list[str], other: list[str]) -> list[str]:
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

    return diff


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog = sys.argv[0],
        description = DESCRIPTION)
    parser.add_argument('--values', required=True)
    parser.add_argument('--readme', required=True)
    args = parser.parse_args()

    main(args.values, args.readme)
