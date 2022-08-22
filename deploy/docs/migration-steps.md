# Migration steps from `SumoLogic/fluentd-kubernetes-sumologic`

Our [old collection method](https://github.com/SumoLogic/fluentd-kubernetes-sumologic)
includes Fluentd for logs and Heapster for metrics.

- If you plan to deploy the new collection method to the same namespace where
  the old method was deployed to, you will need to delete the resources
  associated with Fluentd and Heapster first.
- If you plan to deploy in a different namespace, you can set up the new
  collection method before deleting the resources to avoid losing any data.
  They should both be able to run at the same time and while there will be some duplication,
  there won’t be any loss in data.

To delete the old collection method, you will need to delete the deployment for both Fluentd and Heapster:

Find the resources associated with the old collection method:

```
kubectl get all --all-namespaces
```

This will show you all pods/namespaces/deployments/services and make sure you don’t miss
things that may have been deployed in different namespaces.

## Delete the resources associated with Fluentd

Find the fluentd daemonset:

```
kubectl get daemonsets
```

Delete the RBAC resources if you set up the old solution with RBAC:

```
kubectl delete serviceaccount fluentd
kubectl delete clusterrole fluentd
kubectl delete clusterrolebinding fluentd
```

Delete the Fluentd daemonset, configmap and secret:

```
kubectl delete daemonset fluentd-sumologic
kubectl delete configmap fluentd-sumologic-config
kubectl delete secret sumologic
```

## Delete the resources associated with Heapster

Remove the Graphite Sink for Heapster.
Assuming you have used the
[YAML files suggested by our old method](https://github.com/SumoLogic/fluentd-kubernetes-sumologic#step-4-set-up-heapster-for-metric-collection),
the sink option to be removed would be `--sink=graphite:tcp://sumo-graphite.kube-system.svc:2003`.

Delete the service, deployment and configmap for Heapster:

```
kubectl delete service sumo-graphite
kubectl delete deployment sumo-graphite
kubectl delete configmap sumo-sources
```
