import argparse

import kops
import eks
import gke
import aks
import openshift

import helm_charts

parser = argparse.ArgumentParser(
    prog="dependency_checker",
    description="dependency_checker checks whether any dependencies or supported platforms need to be updated"
)
parser.add_argument("-q", "--quiet", action="store_true")

if __name__ == "__main__":
    args = parser.parse_args()
    output_lines = []
    output_lines.append("Gardener helper")
    output_lines.append("#####################################################################")
    output_lines.append("")
    output_lines.extend(kops.get_info())
    output_lines.extend(eks.get_info())
    output_lines.extend(gke.get_info())
    output_lines.extend(aks.get_info())
    output_lines.extend(openshift.get_info())

    if not len(output_lines) == 3:
        output_lines.append("")

    output_lines.extend(helm_charts.get_info())

    if len(output_lines) == 3:
        output_lines.append("No changes are required")

    if not args.quiet or len(output_lines) > 4:
        for line in output_lines:
            print(line)
