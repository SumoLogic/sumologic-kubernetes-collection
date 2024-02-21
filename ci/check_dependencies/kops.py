import requests
import traceback
import os
import json
import kubernetes_collection
import common

kops_line_pattern = "K8s with Kops"


# ref: https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#list-releases
def get_releases(owner, repo):
    result = requests.get(
        "https://api.github.com/repos/{owner}/{repo}/releases".format(
            owner=owner, repo=repo
        )
    )
    if result.status_code == 200:
        return result.json()
    return None


def get_minor_releases(owner, repo):
    try:
        releases = get_releases(owner, repo)

        minor_releases = set()
        for release in releases:
            release_name_digits = release["name"].strip("v").split(".")
            minor_releases.add(
                "{major}.{minor}".format(
                    major=release_name_digits[0], minor=release_name_digits[1]
                )
            )
    except IndexError:
        print("Wrong format of release name, name={}".format(release["name"]))
        traceback.print_exc()
    return sorted(minor_releases)


def get_expected_supported_kops(kops_releases):
    # we support kOps in the latest version and 4 versions backwards so e.g. when 1.25 is the latest version of kOps we support 1.21 - 1.25
    # so we support 5 latest kops releases
    return kops_releases[-5:]


def get_info() -> list[str]:
    # Figure out which versions we need to add/remove 
    kops_minor_releases = get_minor_releases("kubernetes", "kops")
    officially_supported = get_expected_supported_kops(kops_minor_releases)
    return common.get_info("Kops", officially_supported)