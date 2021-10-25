#!/usr/bin/env python3
"""
This script search prometheus rules files by name and prints
which object contains it and what is the expression to describe it
Usage:

kubectl get prometheusrules -oyaml > out.yaml
./prometheus-rules-getter.py out.yaml <name of the rule>
"""
import sys

import yaml
from yaml.loader import SafeLoader

if len(sys.argv) < 3:
    sys.exit()

with open(sys.argv[1]) as f:
    monitors = yaml.load(f.read(), Loader=SafeLoader)

for monitor in monitors['items']:
    for group in monitor['spec']['groups']:
        for rule in group['rules']:
            if rule.get('record') == sys.argv[2]:
                print(monitor['metadata']['namespace'], monitor['metadata']['name'])
                print(rule['expr'])
