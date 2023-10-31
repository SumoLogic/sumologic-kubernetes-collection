#!/usr/bin/env python3

import argparse
from http import client, HTTPStatus
from yaml import load, dump, Loader

REPO = "SumoLogic/sumologic-kubernetes-collection"
HOST = "github.com"
RAW_HOST = "raw.githubusercontent.com"
FILE = "deploy/helm/sumologic/values.yaml"
AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/118.0"


def main():
    parser = argparse.ArgumentParser(
        prog="SKC values diff",
        description="Return customer overrides over default values.yaml",
    )

    parser.add_argument("filename")
    parser.add_argument("-v", "--version")

    args = parser.parse_args()
    default_values = load(get_values(args.version), Loader)
    with open(args.filename, encoding="utf-8") as file:
        values = load(file.read(), Loader)

    print(dump(remove_duplicates(values, default_values)))


def remove_duplicates(override, defaults):
    if isinstance(override, type(defaults)):
        return override

    if isinstance(override, dict):
        to_remove = []
        for key, value in override.items():
            # If values are the same, mark to remove
            # '' is not None so we need to compare negations of them
            if defaults.get(key) == value or (not defaults.get(key) and not value):
                to_remove.append(key)
                continue

            # values are different, we need to go deeper
            override[key] = remove_duplicates(value, defaults.get(key))

            # no differences
            if override[key] in ({}, []):
                to_remove.append(key)

        # Remove keys marked to remove
        for key in to_remove:
            del override[key]
    elif isinstance(override, list):
        # different length means that list has been overrided
        if len(override) != len(defaults):
            return override

        # if any value differs, return object
        for key, value in enumerate(override):
            if remove_duplicates(defaults[key], value):
                return override

        to_remove = list(range(0, len(override)))
        to_remove.reverse()
        for key in to_remove:
            del override[key]

    return override


def get_values(version: str):
    if version is None:
        conn = client.HTTPSConnection(HOST)
        conn.request(
            "GET",
            f"/{REPO}/releases/latest",
            headers={"Host": HOST, "User-Agent": AGENT},
        )
        response = conn.getresponse()
        if response.status != HTTPStatus.FOUND:
            raise Exception(f"Unexpected response status {response.status}")
        version = response.headers["Location"].removeprefix(
            f"https://{HOST}/{REPO}/releases/tag/"
        )

    conn = client.HTTPSConnection(RAW_HOST)
    conn.request(
        "GET",
        f"/{REPO}/{version}/{FILE}",
        headers={"Host": RAW_HOST, "User-Agent": AGENT},
    )
    response = conn.getresponse()
    if response.status != HTTPStatus.OK:
        raise Exception(f"Unexpected response status {response.status}")

    return response.read()


if __name__ == "__main__":
    main()
