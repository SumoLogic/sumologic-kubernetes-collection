# Installing Behind a Proxy

If your Kubernetes cluster requires outbound traffic to go through a proxy, you will need to set the following properties:

```
sumologic.httpProxy
sumologic.httpsProxy
```

You should set these properties to the URL for your proxy environment.

## TLS interception via a transparent proxy

If the proxy in question is transparent and does TLS interception with a custom root CA, installation becomes a bit more complex.
Installation involves the setup job using the Sumologic API in order to create some necessary resources, like collectors and fields. This
will fail if the Sumologic API TLS certificate cannot be verified.

The recommended way is to inject the custom root CA into the setup image: [see here][rebuilding]

[rebuilding]:
  https://help.sumologic.com/docs/send-data/kubernetes/security-best-practices/#adding-a-custom-root-ca-certificate-by-rebuilding-container-images

## Troubleshooting

### Error: timed out waiting for the condition

If `helm upgrade --install` hangs, it usually means the pre-install setup job is failing and is in a retry loop. Due to a Helm limitation,
errors from the setup job cannot be fed back to the `helm upgrade --install` command. Kubernetes schedules the job in a pod, so you can look
at logs from the pod to see why the job is failing. First find the pod name in the namespace where the Helm chart was deployed. The pod name
will contain `-setup` in the name.

```sh
kubectl get pods
```

If you see the following in the setup job logs:

```
kubernetes_secret.sumologic_collection_secret: Creating...

   Error: Post "https://kubernetes.default.svc/api/v1/namespaces/sumologic/secrets": Service Unavailable

     on resources.tf line 59, in resource "kubernetes_secret" "sumologic_collection_secret":
     59: resource "kubernetes_secret" "sumologic_collection_secret" {
```

It likely means your proxy is restricting access to `https://kubernetes.default.svc`. Get the IP address of that service by running
`kubectl -n default get service kubernetes`and then you can set the following property:

```
sumologic.cluster.host: https://<SERVICE_IP>:443
```
