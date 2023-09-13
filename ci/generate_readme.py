#!/usr/bin/env python3

import argparse
import json
import re
import sys
import os

import yaml
from yaml.loader import SafeLoader

DESCRIPTION = "test"
HEADER = """# Configuration

To see all available configuration for our sub-charts, please refer to their documentation.

- [Falco](https://github.com/falcosecurity/charts/tree/master/charts/falco#configuration) - All Falco properties should be prefixed with
  `falco.` in our values.yaml to override a property not listed below.
- [Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#configuration) - All
  Kube Prometheus Stack properties should be prefixed with `kube-prometheus-stack.` in our values.yaml to override a property not listed
  below.
- [Metrics Server](https://github.com/bitnami/charts/tree/master/bitnami/metrics-server/#parameters) - All Metrics Server properties should
  be prefixed with `metrics-server.` in our values.yaml to override a property not listed below.
- [Tailing Sidecar Operator](https://github.com/SumoLogic/tailing-sidecar/tree/main/helm/tailing-sidecar-operator#configuration) - All
  Tailing Sidecar Operator properties should be prefixed with `tailing-sidecar-operator` in our values.yaml to override a property not
  listed below.
- [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator#opentelemetry-operator-helm-chart) -
  All OpenTelemetry Operator properties should be prefixed with `opentelemetry-operator` in our values.yaml to override a property listed
  below.

The following table lists the configurable parameters of the Sumo Logic chart and their default values.

| Parameter | Description | Default |
| --- | --- | --- |"""

FOOTER = """
[values.yaml]: values.yaml"""

def build_default(data):
  return_value = {}
  if 'properties' in data:
    for key in data['properties']:
      return_value[key] = build_default(data['properties'][key])
    return return_value
  elif 'items' in data:
    return [item['default'] for item in data['items']]
  else:
    return data['default']

def get_description(prefix, data):
    return_value = []
    prefix = prefix.strip('.')
    description = data["description"] if 'description' in data else ""
    built_default = None

    if 'properties' in data:
      if not description:
        for key in data['properties']:
          if prefix == "":
            pref = key
          else:
            if "." in key:
              pref = f"{prefix}[{key}]"
            else:
              pref = f"{prefix}.{key}"
          return_value += get_description(pref, data['properties'][key])
        return return_value
      else:
        built_default = build_default(data)

    if 'items' in data:
        built_default = build_default(data)

    default = json.dumps(built_default if built_default is not None else data['default']).strip('"').replace("|", "\|")
    if len(default) > 180:
      default = "See [values.yaml]"

    if default == "":
      default = "Nil"
    return_value.append(f'| `{prefix}` | {data["description"]} | `{default}` |')

    return return_value

def main(schema, directory):
    readme = [HEADER]
    with open(schema) as f:
        data = json.loads(f.read())
        readme += get_description("", data)
    readme.append(FOOTER)

    readme = "\n".join(readme)

    with open(os.path.join(directory, "README.md"), "w") as f:
      f.write(readme)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog = sys.argv[0],
        description = DESCRIPTION)
    parser.add_argument('--schema', required=True)
    parser.add_argument('--dir', required=True)
    parser.add_argument('--full-diff', required=False, action='store_true')
    args = parser.parse_args()

    main(args.schema, args.dir)
