import kops
import eks
import gke
import aks
import openshift

import helm_charts

if __name__ == "__main__":
    print("Gardener helper")
    print("#####################################################################\n")
    print("#### kOps ####")
    kops.get_info()
    print("")
    print("#### EKS ####")
    eks.get_info()
    print("")
    print("#### GKE ####")
    gke.get_info()
    print("")
    print("#### AKS ####")
    aks.get_info()
    print("")
    print("#### OpenShift ####")
    openshift.get_info()
    print("")

    print("#### Subcharts in Sumologic Kubernetes Collection Helm Chart ####")
    print("")
    helm_charts.get_info()
