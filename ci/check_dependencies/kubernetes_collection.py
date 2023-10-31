import requests
import traceback
import os
import json
import kubernetes_collection


def get_kubernetes_collection_readme():
    result = requests.get(
        "https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/main/docs/README.md"
    )
    if result.status_code == 200:
        return result.text
    return None


def get_platform_readme_line(readme, line_pattern):
    lines = readme.split("\n")
    platform_line = ""
    for line in lines:
        if line_pattern in line:
            platform_line = line
            break
    return platform_line.strip()


def get_platform_versions_from_readme(readme, line_pattern):
    platform_line = get_platform_readme_line(readme, line_pattern)
    platform_table = [x for x in platform_line.split("|") if x]
    versions = platform_table[1].strip().split("<br/>")
    return sorted(versions)


def get_supported_versions(line_pattern):
    readme = get_kubernetes_collection_readme()
    versions = get_platform_versions_from_readme(readme, line_pattern)
    return versions
