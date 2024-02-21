import requests
import os
import json
import lxml.html as lh
import traceback

import requests
from bs4 import BeautifulSoup
import pandas as pd
from datetime import datetime, timedelta

import common


def get_pd_dataframe_from_html(html):
    soup = BeautifulSoup(html, "lxml")

    # get information from second table on web page
    calendar_table = soup.select_one("table:nth-of-type(1)")

    # Obtain every title of columns with tag <th>
    headers = []
    for i in calendar_table.find_all("th"):
        title = i.text
        headers.append(title)

    data = pd.DataFrame(columns=headers)

    # Create a for loop to fill pandas dataframe
    for j in calendar_table.find_all("tr")[1:]:
        row_data = j.find_all("td")
        row = [i.text for i in row_data]
        length = len(data)
        data.loc[length] = row

    return data


def get_supported_releases(html_calendar):
    pd_data = get_pd_dataframe_from_html(html_calendar)

    # AKS adds an asterisk to the LTS version, we remove it
    pd_data["K8s version"] = pd_data["K8s version"].apply(lambda s: s.strip("*"))

    pd_data = pd_data.set_index("K8s version")
    pd_data["AKS GA date"] = pd.to_datetime(
        pd_data["AKS GA"], format="%b %Y", errors="coerce"
    ).fillna(datetime.now() + timedelta(days=50 * 365))
    pd_data["AKS Preview date"] = pd.to_datetime(
        pd_data["AKS preview"], format="%b %Y", errors="coerce"
    ).fillna(datetime.now() + timedelta(days=50 * 365))
    today = datetime.now()
    supported_releases = []
    for index, row in pd_data.iterrows():
        if row["AKS Preview date"] < today:
            dependent_version = row["Platform support"].replace("GA", "").replace("Until", "").strip()
            if dependent_version in pd_data.index:
                dependent_version_GA_date = pd_data.loc[dependent_version][
                    "AKS GA date"
                ]
                if dependent_version_GA_date > today:
                    supported_releases.append(index)
            else:
                supported_releases.append(index)
    return supported_releases


def get_info() -> list[str]:
    cache_file = "cache/aks_calendar.html"
    calendar_web_page = "https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli#aks-kubernetes-release-calendar"
    html_calendar = common.get_page(calendar_web_page, cache_file)
    officially_supported = get_supported_releases(html_calendar)
    return common.get_info("AKS", officially_supported)
