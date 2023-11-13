import os
import json
import lxml.html as lh
import traceback

import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta

import common

# versions which are supported by Openshift but it is not desired to support them in sumologic kubernetes collection
excluded_from_collection_support = {"3.11"}


def get_options_in_versions_selector(html):
    soup = BeautifulSoup(html, "lxml")
    version_select = soup.find("select", id="version-selector")
    options = version_select.find_all("option")
    return [x.get_text() for x in options]


def get_supported_releases(html_calendar):
    lines = html_calendar.split("\n")
    unsupported_versions_line = ""
    for line in lines:
        if "unsupported_versions =" in line:
            unsupported_versions_line = line

    unsupported_versions = (
        unsupported_versions_line.replace("unsupported_versions =", "")
        .replace("[", "")
        .replace("]", "")
        .replace('"', "")
        .replace(";", "")
        .replace(" ", "")
        .split(",")
    )
    options = get_options_in_versions_selector(html_calendar)
    supported_versions = (
        set(options) - set(unsupported_versions) - excluded_from_collection_support
    )

    return sorted(supported_versions)


def get_info() -> str:
    cache_file = "cache/openshift_calendar.html"
    # template for https://docs.openshift.com/container-platform/4.11/welcome/index.html
    calendar_web_page = "https://raw.githubusercontent.com/openshift/openshift-docs/main/_templates/_page_openshift.html.erb"
    html_calendar = common.get_page(calendar_web_page, cache_file)
    officially_supported = get_supported_releases(html_calendar)
    return common.get_info("OpenShift", officially_supported)
