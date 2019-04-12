# Deployment Guide (Draft)

## Prerequests

* Make sure a Kubernetes cluster is created and you can use `kubectl` to access it.
* Make sure Kubernetes cluster enables the DNS service ([steps](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/#dns))
* Create HTTP source(s) in your Sumo Logic account and get HTTP Source URL(s).

## Setting up Fluentd

* Download kubernetes .yaml manifest files from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/fluentd-sumologic.yaml
```

* Open the .yaml file, find line with `endpoint-metrics:`, replace `XXXX` with the URL of HTTP source; save it.
* Apply the .yaml file with `kubectl`:

```sh
kubectl apply -f ./fluentd-sumologic.yaml
```

* Verify the pod(s) are running:

```sh
kubectl -n sumologic get pod
```

## Setting up Prometheus

* Install `helm`:

```sh
brew install kubernetes-helm
```

* Download tiller RBAC .yaml manifest files from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/tiller-rbac.yaml
```

* Apply the .yaml file with `kubectl` and init tiller:

```sh
kubectl apply -f tiller-rbac.yaml \
  && helm init --service-account tiller
```

* Download Prometheus operator override .yaml files from GitHub:

```sh
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/overrides.yaml
```

* Install the `prometheus-operator` using `helm`:

```sh
helm repo update \
   && helm install stable/prometheus-operator --name prometheus-operator --namespace sumologic -f overrides.yaml
```

__NOTE__: If credentials are created earlier, add `--no-crd-hook` at the end.

* Verify the `prometheus-operator` is running:

```sh
kubectl -n sumologic logs prometheus-prometheus-operator-prometheus-0 prometheus -f
```

## Tearing down

* Delete `prometheus-operator` from the Kubernetes cluster:

```sh
helm del --purge prometheus-operator
```

* Delete `fluentd-sumologic` app:

```sh
kubectl delete -f ./fluentd-sumologic.yaml
```
