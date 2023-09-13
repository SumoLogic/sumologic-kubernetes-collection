#!/usr/bin/env python3

import unittest
from generate_values import dump_to_string, generate_values

class DumpCase:
    def __init__(self, object, expected):
        self.object = object
        self.expected = expected

class ValuesCase:
    def __init__(self, object, expected):
        self.object = object
        self.expected = expected

class TestDump(unittest.TestCase):
    cases = [
        DumpCase('test', 'test'),
        DumpCase({
            'a': 'b',
            'c': 'd'
            },
            '''a: b
c: d'''),
        DumpCase({'e': {
            'a': 'b',
            'c': 'd'
            }},
            '''e:
  a: b
  c: d'''),
        DumpCase([{
            'a': 'b',
            'c': 'd'
            }],
            '''- a: b
  c: d'''),
        DumpCase({'a': {}},
            '''a: {}'''),
        DumpCase({'a': []},
            '''a: []'''),
        DumpCase({'a': ''},
            '''a:'''),
        DumpCase([
                {
                  "name": "init-falco",
                  "image": "public.ecr.aws/docker/library/busybox:1.36.0",
                  "command": [
                    "sh",
                    "-c",
                    "while [ -f /host/etc/redhat-release ] && [ -z \"$(ls /host/usr/src/kernels)\" ] ; do\necho \"waiting for kernel headers to be installed\"\nsleep 3\ndone\n"
                  ],
                  "volumeMounts": [
                    {
                      "mountPath": "/host/usr",
                      "name": "usr-fs",
                      "readOnly": True
                    },
                    {
                      "mountPath": "/host/etc",
                      "name": "etc-fs",
                      "readOnly": True
                    }
                  ]
                }
              ],
            '''- name: init-falco
  image: public.ecr.aws/docker/library/busybox:1.36.0
  command:
    - sh
    - -c
    - |
      while [ -f /host/etc/redhat-release ] && [ -z "$(ls /host/usr/src/kernels)" ] ; do
      echo "waiting for kernel headers to be installed"
      sleep 3
      done
  volumeMounts:
    - mountPath: /host/usr
      name: usr-fs
      readOnly: true
    - mountPath: /host/etc
      name: etc-fs
      readOnly: true'''),
    ]

    def test(self):
        self.maxDiff = None
        for case in self.cases:
            self.assertEqual(case.expected, dump_to_string(case.object))

class TestDump(unittest.TestCase):
    cases = [
        ValuesCase({
                "properties": {
                    "cAdvisorMetricRelabelings": {
                    "type": "array",
                    "comment": "see docs/scraped_metrics.md\ncadvisor container metrics",
                    "description": "Kubelet CAdvisor MetricRelabelConfigs",
                    "items": [
                        {
                        "default": {
                            "action": "keep",
                            "regex": "(?:container_cpu_usage_seconds_total|container_memory_working_set_bytes)",
                            "sourceLabels": [
                            "__name__"
                            ]
                        }
                        },
                        {
                        "comment": "Drop container metrics with container tag set to an empty string:\nthese are the pod aggregated container metrics which can be aggregated\nin Sumo anyway. There's also some cgroup-specific time series we also\ndo not need.",
                        "default": {
                            "action": "drop",
                            "sourceLabels": [
                            "__name__",
                            "container"
                            ],
                        }
                        }
                    ]
                    }
                }
            }, '''## see docs/scraped_metrics.md
## cadvisor container metrics
cAdvisorMetricRelabelings:
- action: keep
  regex: (?:container_cpu_usage_seconds_total|container_memory_working_set_bytes)
  sourceLabels:
    - __name__
## Drop container metrics with container tag set to an empty string:
## these are the pod aggregated container metrics which can be aggregated
## in Sumo anyway. There's also some cgroup-specific time series we also
## do not need.
- action: drop
  sourceLabels:
    - __name__
    - container''')
    ]

    def test(self):
        self.maxDiff = None
        for case in self.cases:
            self.assertEqual(case.expected, '\n'.join(generate_values('', case.object)))

if __name__ == '__main__':
    unittest.main()
