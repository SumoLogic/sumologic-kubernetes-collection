# Tear down

To delete `falco` from the Kubernetes cluster:

```sh
helm del --purge falco
```

To delete `fluent-bit` from the Kubernetes cluster:

```sh
helm del --purge fluent-bit
```

To delete `prometheus-operator` from the Kubernetes cluster:

```sh
helm del --purge prometheus-operator
```

__NOTE__ This command will not remove the Custom Resource Definitions created.

To delete the `fluentd-sumologic` app:

```sh
kubectl delete -f ./fluentd-sumologic.yaml
```

To delete the `sumologic` secret (for recreating collector/sources):

```sh
kubectl -n sumologic delete secret sumologic
```

To delete the `sumologic` namespace and all resources under it:

```sh
kubectl delete namespace sumologic
```
