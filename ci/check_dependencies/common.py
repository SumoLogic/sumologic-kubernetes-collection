import kubernetes_collection

import requests
import os
import json
import lxml.html as lh
import traceback

import requests
from bs4 import BeautifulSoup
import pandas as pd
from datetime import datetime, timedelta

cache_path = "cache/"


def prepare_cache_dir():
    if not os.path.exists(cache_path):
        os.makedirs(cache_path)


def is_cache_updated(cache_file):
    if os.path.isfile(cache_file):
        return True
    return False


def get_page(web_page, cache_file):
    prepare_cache_dir()
    calendar = ""
    if is_cache_updated(cache_file):
        # print("{} available in cache, getting from file".format(web_page))
        with open(cache_file, "r") as f:
            calendar = f.read()
    else:
        # print("{} not available in cache".format(web_page))
        result = requests.get(web_page)
        if result.status_code == 200:
            with open(cache_file, "w") as f:
                f.write(result.text)
                calendar = result.text
    return calendar


def get_info(platform, officially_supported) -> list[str]:
    output_lines = []
    if platform == "OpenShift":
        line_pattern = platform
    else:
        line_pattern = "K8s with {}".format(platform)

    now_suppported = kubernetes_collection.get_supported_versions(line_pattern)
    versions_to_add = sorted(set(officially_supported) - set(now_suppported))
    versions_to_remove = sorted(set(now_suppported) - set(officially_supported))

    if len(versions_to_add) == 0 and len(versions_to_remove) == 0:
        return []

    output_lines.append(f"")
    output_lines.append(f"#### {platform} ####")
    output_lines.append("{} officially supported versions".format(platform))
    output_lines.append(officially_supported)

    output_lines.append(
        "Currently supported {} versions for Sumologic Kubernetes Collection Helm Chart".format(
            platform
        )
    )
    
    output_lines.append(now_suppported)
    output_lines.append("\n")

    
    if len(versions_to_add) != 0:
        output_lines.append("Please add support to following {} versions:".format(platform))
        output_lines.append(versions_to_add)

    
    if len(versions_to_remove) != 0:
        output_lines.append("Please remove support to following {} versions:".format(platform))
        output_lines.append(versions_to_remove)
    
    return output_lines
