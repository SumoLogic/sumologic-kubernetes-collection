import requests
import traceback
import os
import json
import kubernetes_collection

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
            if "alpha" in release["name"] or "beta" in release["name"]:
                continue
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


def get_info():
    print("kOps latest versions from https://github.com/kubernetes/kops/releases")
    kops_minor_releases = get_minor_releases("kubernetes", "kops")
    print(kops_minor_releases)

    print(
        "Currently supported kOps versions for Sumologic Kubernetes Collection Helm Chart"
    )
    kops_now_suppported = kubernetes_collection.get_supported_versions(
        kops_line_pattern
    )
    print(kops_now_suppported)

    print(
        "Expected supported kOps versions for Sumologic Kubernetes Collection Helm Chart"
    )
    kops_expected_supported = get_expected_supported_kops(kops_minor_releases)
    print(kops_expected_supported)

    versions_to_add = sorted(set(kops_expected_supported) - set(kops_now_suppported))
    if len(versions_to_add) != 0:
        print("\nPlease add support to following kOps versions:")
        print(versions_to_add)

    versions_to_remove = sorted(set(kops_now_suppported) - set(kops_expected_supported))
    if len(versions_to_remove) != 0:
        print("Please remove support to following kOps versions:")
        print(versions_to_remove)
