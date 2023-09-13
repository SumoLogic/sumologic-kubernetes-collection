#!/usr/bin/env python3

import argparse
import json
import re
import sys

import yaml
from yaml.loader import SafeLoader

DESCRIPTION = 'This program generates JSON schema from README.md table'

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

def set_properties(values):
    properties = {
        'type': '',
        # 'required': [],
        # 'properties': {},
        # 'default': '',
        'description': '',
    }

    if isinstance(values, dict):
        properties['type'] = 'object'
        properties['properties'] = {}
        for key in values.keys():
            properties['properties'][key] = set_properties(values[key])
    else:
        properties['default'] = values
        if isinstance(values, bool):
            properties['type'] = 'boolean'
        elif isinstance(values, int):
            properties['type'] = 'integer'
        elif isinstance(values, (list, set)):
            properties['type'] = 'array'
        elif isinstance(values, str):
            properties['type'] = 'string'
        else:
            properties['type'] = 'string'
            if not properties['default']:
                properties['default'] = ""

    return properties

def extract_description_from_readme(path: str) -> dict:
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
            description = match.group('description').strip('`').strip('"')
            keys[match.group('key')] = description

    return keys

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog = sys.argv[0],
        description = DESCRIPTION)
    parser.add_argument('--values', required=True)
    parser.add_argument('--readme', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--full-diff', required=False, action='store_true')
    args = parser.parse_args()

    values = values_to_dictionary(args.values)

    output = {
        "$schema": "http://json-schema.org/schema#",
        "type": "object",
        "properties": {},
    }

    for key in values:
        output['properties'][key] = set_properties(values[key])

    descriptions = extract_description_from_readme(args.readme)
    for key, description in descriptions.items():
        a = output['properties']
        subkeys = key.split(".")
        for i in range(0, len(subkeys)-1):
            a = a[subkeys[i]]['properties']
        a[subkeys[-1]]['description'] = description
    with open(args.output, "w") as f:
        f.write(json.dumps(output, indent=2))
