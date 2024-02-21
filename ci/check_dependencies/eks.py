import requests
import traceback
import os
import json
from datetime import datetime
import kubernetes_collection
import common


def get_eks_doc_from_github():
    result = requests.get(
        "https://raw.githubusercontent.com/awsdocs/amazon-eks-user-guide/main/doc_source/kubernetes-versions.md"
    )
    if result.status_code == 200:
        return result.text
    return None


def get_eks_calendar_table(doc):
    lines = doc.split("\n")
    eks_calendar_table = []

    found_calendar = False
    for line in lines:
        if "| --- |" in line:
            found_calendar = True
        elif found_calendar:
            if line != "":
                eks_calendar_table.append(line)
            else:
                break
    return eks_calendar_table


def parse_eks_end_of_support_date(date):
    try:
        date_elements_len = len(date.split(" "))

        if date_elements_len == 2:
            end_of_support_date = datetime.strptime(date, "%B %Y")
        else:
            end_of_support_date = datetime.strptime(date, "%B %d, %Y")
        return end_of_support_date
    except:
        print("Unexpected date format, date={}".format(date))
        traceback.print_exc()


def get_eks_officially_supported_releases():
    doc = get_eks_doc_from_github()
    eks_calendar_table = get_eks_calendar_table(doc)
    today = datetime.now()

    eks_supported_releases = []
    for row in eks_calendar_table:
        elements = [x for x in row.strip().split("|") if x]
        release_version = elements[0].replace("\\", "").strip()
        end_of_standard_support = elements[3].strip()
        eof_of_support_date = parse_eks_end_of_support_date(end_of_standard_support)
        if today < eof_of_support_date:
            eks_supported_releases.append(release_version)
    return sorted(eks_supported_releases)


def get_info() -> list[str]:
    officially_supported = get_eks_officially_supported_releases()
    return common.get_info("EKS", officially_supported)
