import kops
import eks
import gke
import aks
import openshift

import helm_charts

if __name__ == "__main__":
    print("Gardener helper")
    print("#####################################################################\n")
    kops.get_info()
    eks.get_info()
    gke.get_info()
    aks.get_info()
    openshift.get_info()
    print("")

    print("#### Subcharts in Sumologic Kubernetes Collection Helm Chart ####")
    print("")
    helm_charts.get_info()
