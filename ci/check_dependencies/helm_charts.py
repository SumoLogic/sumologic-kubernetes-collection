import common
import yaml


import pandas as pd
from datetime import datetime


time_format = "%Y-%m-%dT%H:%M:%S.%fZ"
time_formate_with_zone = "%Y-%m-%dT%H:%M:%S.%f%z"
VERSION_IDX = 0
CREATED_IDX = 1

# We ignore Prometheus here, as we're locked to whatever version is CRD-compatible with OpenShift
DEPENDENCIES_TO_IGNORE=("kube-prometheus-stack", "falco")

def get_info() -> list[str]:
    output_lines = []
    cache_file = "cache/Chart.yaml"
    chart_yaml_url = "https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/main/deploy/helm/sumologic/Chart.yaml"
    collection_chart_yaml_str = common.get_page(chart_yaml_url, cache_file)
    chart_yaml = yaml.safe_load(collection_chart_yaml_str)
    deps = chart_yaml["dependencies"]

    for dep in deps:
        if dep["name"] in DEPENDENCIES_TO_IGNORE:
            continue
        index_page = "{}/{}".format(dep["repository"], "index.yaml")
        cache_file = "{}/{}.yaml".format("cache", dep["name"])
        current_version = dep["version"]
        dep_index_yaml_str = common.get_page(index_page, cache_file)
        dep_yaml = yaml.safe_load(dep_index_yaml_str)

        dep_entries = dep_yaml["entries"][dep["name"]]

        pd_entries = pd.DataFrame(columns=["version", "created"])
        for entry in dep_entries:
            row = [entry["version"], entry["created"]]
            length = len(pd_entries)
            pd_entries.loc[length] = row

        pd_entries["created"] = pd_entries["created"].str.replace("Z", "+00:00")
        pd_entries["created date"] = pd.to_datetime(
            pd_entries["created"], format=time_formate_with_zone
        )

        pd_sorted_entries = pd_entries.sort_values("created date", ascending=False)
        latest_release = pd_sorted_entries.loc[0].values
        current_release = (
            pd_sorted_entries.loc[pd_sorted_entries["version"] == current_version]
            .values.flatten()
            .tolist()
        )

        if current_release[VERSION_IDX] != latest_release[VERSION_IDX]:
            output_lines.append(
                "Please check newer version of {} subchart, version: {}, created: {}".format(
                    dep["name"].upper(),
                    latest_release[VERSION_IDX],
                    latest_release[CREATED_IDX],
                )
            )
            output_lines.append(
                "Currently used {} subchart, version: {}, created: {}".format(
                    dep["name"].upper(),
                    current_release[VERSION_IDX],
                    current_release[CREATED_IDX],
                )
            )
            output_lines.append("")
    
    if len(output_lines) > 0:
        output_lines = ["#### Subcharts in Sumologic Kubernetes Collection Helm Chart ####", ""] + output_lines

    return output_lines
