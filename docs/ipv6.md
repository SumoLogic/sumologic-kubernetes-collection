# IPV6 Support

Supports EKS IPv6 clusters and any other k8’s cluster type which has IPv6(Cluster)->IPv4(Internet) Egress communication enabled

## Pre-requisites for EKS Cluster

### 1. Ensure Amazon VPC CNI plugin v1.10.1 or later is deployed in cluster

IP prefix delegation and ENABLE_IPv6 settings must be enabled. If you already deployed VPC-CNI Plugin while creating the cluster, these will
be enabled automatically. If you adding the plugin to an existing cluster, please add the plugin and ensure these settings are enabled.

Create VPC-CNI addon:

```bash
aws eks create-addon --cluster-name my-cluster --addon-name vpc-cni --addon-version v1.20.0-eksbuild.1 \
--service-account-role-arn arn:aws:iam::111122223333:role/AmazonEKSVPCCNIRole
```

For more information and different methods to create the plugin, please refer:
https://docs.aws.amazon.com/eks/latest/userguide/vpc-add-on-create.html

Adjust VPC-CNI configuration:

```bash
aws eks update-addon \
  --cluster-name <your-cluster> \
  --addon-name vpc-cni \
  --configuration-values '{
    "env": {
      "ENABLE_IPv6": "true",
      "ENABLE_PREFIX_DELEGATION": "true",
      "WARM_PREFIX_TARGET": "1"
    }
  }'
```

For more information and different methods to update plugin settings, please refer
https://docs.aws.amazon.com/eks/latest/userguide/updating-an-add-on.html

### 2. Route table with ipv4 external route

Make sure that VPC’s Route table has a route from IPv4(local) to Internet gateway. Ex. 0.0.0.0/0→igw-XXX (Internet Gateway)

```bash
aws ec2 create-route \
    --route-table-id rtb-xxxxxxxx \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id igw-xxxxxxxx
```

For more information and different methods to add route, please refer
https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc-route-table.html#AddRoutes

## Test ipv6->ipv4 Egress communication

**Deploy a test pod `ipv6-test-pod`**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ipv6-test-pod
  namespace: default
spec:
  containers:
    - name: curl
      image: curlimages/curl:8.9.1
      command: ["sleep", "3600"]
  restartPolicy: Never
```

```bash
kubectl apply -f ipv6-test-pod.yaml
```
**Connect to the test pod and try to connect to an ipv4 endpoint**

```bash
kubectl exec -it ipv6-test-pod -- sh

curl --ipv4 -v http://example.com
```

Curl should succeed connecting.
