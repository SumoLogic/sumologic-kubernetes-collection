#!/usr/bin/env python3

import io
from contextlib import redirect_stdout
from unittest import TestCase
from unittest.mock import patch, mock_open
from .check_configuration_keys import main


class TestObject:
    def __init__(self, name, values, readme, expected="", exception=None):
        self.name = name
        self.readme = readme
        self.values = values
        self.exception = exception
        self.expected = expected


class MainTest(TestCase):
    def test_outputs(self):
        cases = [
            TestObject(
                "simple test",
                "test: abc",
                "| `test` | test | abc |",
            ),
            # Ensure that `#`` is treated as commented code
            TestObject(
                "commented line",
                """
a: b
c:
  d: e
  # test: abc""",
                """
| `a` | test | b |
| `c.d` | test | e |
| `c.test` | test | abc |""",
            ),
            # Ensure that `##`` is treated as comment
            TestObject(
                "double commented line",
                """
a: b
c:
  d: e
  ## test: abc""",
                """
| `a` | test | b |
| `c.d` | test | e |""",
            ),
        ]

        for case in cases:
            mock_files = [
                mock_open(read_data=content).return_value
                for content in (case.values, case.readme)
            ]
            mock_opener = mock_open()
            mock_opener.side_effect = mock_files
            buf = io.StringIO()

            with self.subTest(name=case.name):
                with patch("builtins.open", mock_opener):
                    with redirect_stdout(buf):
                        if case.exception:
                            with self.assertRaises(case.exception):
                                main("values.yaml", "readme.md")
                        else:
                            main("values.yaml", "readme.md")
                    self.assertEqual(case.expected, buf.getvalue())
