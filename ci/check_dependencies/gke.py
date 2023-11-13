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
    # parser-lxml = Change html to Python friendly format
    soup = BeautifulSoup(html, "lxml")

    # get information from first table on web page
    calendar_table = soup.select_one("table:nth-of-type(1)")

    # remove all <sup></sup> from table
    for sup in calendar_table.find_all("sup"):
        sup.decompose()

    # # Obtain every title of columns with tag <th>
    # headers = []
    # for i in calendar_table.find_all('th'):
    #   title = i.text
    #   headers.append(title)

    # # remove not needed header
    # headers.remove('Control plane and node upgrades start on/after')
    # headers = [x.strip() for x in headers]

    headers = [
        "Kubernetes version",
        "Kubernetes release date",
        "Rapid available",
        "Rapid upgrade",
        "Regular available",
        "Regular upgrade",
        "Stable available",
        "Stable upgrade",
        "End of life",
    ]
    data = pd.DataFrame(columns=headers)

    # Create a for loop to fill pandas dataframe
    for j in calendar_table.find_all("tr")[2:]:  # two first rows are empty
        row_data = j.find_all("td")
        row = [i.text for i in row_data]
        length = len(data)
        data.loc[length] = row

    return data


def parse_gke_dates(date):
    try:
        date_elements_len = len(date.split("-"))
        date_converted = None
        if date_elements_len == 3:
            date_converted = datetime.strptime(date, "%Y-%m-%d")
        else:
            if "Q" in date or date == "TBD":
                # TODO: add better parsing of dates with Q
                # now sets date from the future, Q is used for not published releases
                date_converted = datetime.now() + timedelta(days=50 * 365)
            else:
                date_converted = datetime.strptime(date, "%Y-%m")

        return date_converted
    except:
        print("Unexpected date format, date={}".format(date))
        traceback.print_exc()


def get_supported_releases(html_calendar):
    pd_data = get_pd_dataframe_from_html(html_calendar)
    today = datetime.now()

    supported_releases = []
    for index, row in pd_data.iterrows():
        end_of_life_date = parse_gke_dates(row["End of life"])
        regular_release_date = parse_gke_dates(row["Regular available"])
        if regular_release_date < today and today < end_of_life_date:
            supported_releases.append(row["Kubernetes version"])
    return supported_releases


def get_info() -> list[str]:
    cache_file = "cache/gke_calendar.html"
    calendar_web_page = "https://cloud.google.com/kubernetes-engine/docs/release-schedule#schedule_for_release_channels"
    html_calendar = common.get_page(calendar_web_page, cache_file)
    officially_supported = get_supported_releases(html_calendar)
    return common.get_info("GKE", officially_supported)
