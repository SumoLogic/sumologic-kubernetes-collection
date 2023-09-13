#!/usr/bin/env python3

import unittest
from diff_values import remove_duplicates


class Case:
    def __init__(self, default, override, expected):
        self.default = default
        self.override = override
        self.expected = expected


class TestDump(unittest.TestCase):
    cases = [
        Case({"a": ["container", "uid"]}, {"a": ["container"]}, {"a": ["container"]}),
        Case(
            {"a": ["container"]},
            {"a": ["container", "uid"]},
            {"a": ["container", "uid"]},
        ),
        Case(
            {"a": ["container", "pod"]},
            {"a": ["container", "uid"]},
            {"a": ["container", "uid"]},
        ),
        Case({"a": ["container", "pod"]}, {"a": ["container", "pod"]}, {}),
        Case({"a": [{"b": ""}]}, {"a": [{"b": None}]}, {}),
    ]

    def test(self):
        self.maxDiff = None
        for case in self.cases:
            self.assertEqual(
                case.expected, remove_duplicates(case.override, case.default)
            )


if __name__ == "__main__":
    unittest.main()
