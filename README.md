# sumologic-kubernetes-collection

# Installation

First use `kops` to deploy your Kubernetes cluster in your AWS account.

## Setting up Fluentd

1. Clone this repo and navigate to `./deploy/kubernetes`.
2. Create an HTTP source in your Sumo Logic account to get an HTTP Source URL.
3. Run `echo -n '<YOUR_HTTP_URL>' | base64` to encode your HTTP Source URL.
4. In `secret-sumologic.yaml`, under `endpoint-metrics:`, replace `XXXX` with the encoded URL from step 3.
5. Ensure you are in the correct directory `./deploy/kubernetes`. Install the fluentd plugins using `kubectl`:
```
kubectl apply -f ./namespace-sumologic.yaml -f ./secret-sumologic.yaml -f ./deployment-fluentd.yaml
```
****Note:** Ideally we'd be able to run `kubectl apply -f .`, which applies all files in the directory. However there is a longstanding [issue](https://github.com/kubernetes/kubernetes/issues/16448) with `kubectl` that causes it to be unable to find the created namespace before trying to create the objects specified in `deployment-fluentd.yaml` which depend on that namespace. Thus for now we have to specify the order of the files (or rename the files such that they are alphabetically in the correct order).*

## Setting up Prometheus

1. Install `helm`.
```
brew install kubernetes-helm
```
2. Create the necessary RBAC role in your Kubernetes cluster by creating a [`tiller-rbac.yaml`](https://docs.google.com/document/d/1Iu1zqTusPALc0I7rfIz9S7yLQ941JVfAO2qZWmovKwE/edit?usp=sharing) file. Then run
```
kubectl create -f tiller-rbac.yaml
```
3. Install `tiller`.
```
helm init --service-account tiller
```
4. Run `kubectl get svc -n sumologic`. The output should look something like this:
```
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)          AGE
fluentd   LoadBalancer   123.45.67.890   abcdefghijklmnopqrstuvwxyz-1234567890.us-west-1.elb.amazonaws.com   1234:56789/TCP   11m
```
5. Create a `values.yaml` file with the following format, using the `EXTERNAL-IP` and `PORT` from above. The url should look like `http://abcdefghijklmnopqrstuvwxyz-1234567890.us-west-1.elb.amazonaws.com:1234/prometheus.metrics`.
```
prometheus:
  prometheusSpec:
    remoteWrite:
    - url: http://<EXTERNAL-IP>:<PORT>/prometheus.metrics
```
6. Install the `prometheus-operator` using `helm`:
```
helm install stable/prometheus-operator --name prometheus-operator --namespace monitoring -f values.yaml
```

At this point, you might get an error:
```
Error: validation failed: [unable to recognize "": no matches for kind "Alertmanager" in version "monitoring.coreos.com/v1", unable to recognize "": no matches for kind "Prometheus" ...
```
This is caused by a helm bug. The [workaround](https://github.com/helm/charts/issues/9941#issuecomment-447844259) is to
1. Delete `prometheus-operator` from the Kubernetes cluster if it was created
```
helm del --purge prometheus-operator
```
2. Delete the four `crd`s that were created
```
kubectl get crd --all-namespaces
kubectl delete crd <crd_name>
```
3. Deploy the four `crd`s first, before attempting to install `prometheus-operator`
```
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
```
4. Finally run the installation command from above, except with the `no-crd-hook` option
```
helm install stable/prometheus-operator --name prometheus-operator --namespace monitoring -f values.yaml --no-crd-hook
```
