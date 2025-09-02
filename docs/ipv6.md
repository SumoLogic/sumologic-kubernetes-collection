# IPV6 Support

Supports EKS IPv6 clusters and any other k8s cluster type which has IPv6(Cluster)-to-IPv4(Internet) Egress communication enabled.

When running an IPv6-only Kubernetes cluster, pods may still need to access external IPv4 endpoints (e.g., APIs, package repositories,
Github which are ipv4 only). This requires configuring the CNI and VPC to support IPv6-to-IPv4 egress via NAT64 and DNS64 components. If
your cluster already has this capability, please skip this and proceed with deploying sumologic helm chart.

## Pre-requisites for EKS Cluster

### 1. Ensure IPv6 settings in your CNI plugin to turn on IPv6 pod addressing

**For Amazon VPC CNI**, Ensure Amazon VPC CNI plugin v1.10.1 or later is deployed in cluster IP prefix delegation and ENABLE_IPv6 settings
must be enabled. If you already deployed VPC-CNI Plugin while creating the cluster, these will be enabled automatically. If you have added
the plugin after the cluster is created, please ensure aforementioned settings are enabled.

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

### 2. Ensure that a NAT Gateway/Internet gateway is provisioned to reach public ipv4 endpoints

#### 2.1. If your worker nodes are in public subnet and you are using AWS VPC-CNI, then please make sure ipv4 external route is added

Make sure that the subnet’s Route table has a route from IPv4(local) to Internet gateway. This is to ensure that ipv4 traffic from your
cluster can reach internet. Ex. 0.0.0.0/0→igw-XXX (Internet Gateway)

```bash
aws ec2 create-route \
    --route-table-id rtb-xxxxxxxx \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id igw-xxxxxxxx
```

For more information and different methods to add route, please refer
https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc-route-table.html#AddRoutes

#### 2.2. If your EKS worker nodes are in private subnet (recommended by AWS) or you are using a custom CNI like Cilium, then please ensure you have provisioned a NAT gateway

If you have a subnet with IPv6-only workloads that needs to communicate with IPv4-only services outside the subnet, this shows you how to
enable these IPv6-only services to communicate with IPv4-only services on the internet.

You should first configure a NAT gateway in a public subnet (separate from the subnet containing the IPv6-only workloads). For example, the
subnet containing the NAT gateway should have a 0.0.0.0/0 route pointing to the internet gateway.

Complete these steps to enable these IPv6-only services to connect with IPv4-only services on the internet:

1. Add the following three routes to the route table of the subnet containing the IPv6-only workloads:

- IPv4 route (if any) pointing to the NAT gateway.

```bash
aws ec2 create-route --route-table-id rtb-34056078 --destination-cidr-block
0.0.0.0/0 --nat-gateway-id nat-05dba92075d71c408
```

- 64:ff9b::/96 route pointing to the NAT gateway. This will allow traffic from your IPv6-only workloads destined for IPv4-only services to
  be routed through the NAT gateway.

```bash
aws ec2 create-route --route-table-id rtb-34056078 --destination-ipv6-cidr-block
64:ff9b::/96 --nat-gateway-id nat-05dba92075d71c408
```

- IPv6 ::/0 route pointing to the egress-only internet gateway (or the internet gateway)

```bash
aws ec2 create-route --route-table-id rtb-34056078 --destination-ipv6-cidr-block
::/0 --egress-only-internet-gateway-id eigw-c0a643a9
```

2. Enable DNS64 capability in the subnet containing the IPv6-only workloads.

```bash
aws ec2 modify-subnet-attribute --subnet-id subnet-1a2b3c4d --enable-dns64
```

For more details on NAT64 and DNS64, please refer https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-nat64-dns64.html

## Test ipv6->ipv4 Egress communication

### Deploy a test pod `ipv6-test-pod`

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

### Connect to the test pod and try to connect to an ipv4 endpoint

```bash
kubectl exec -it ipv6-test-pod -- sh

curl --ipv4 -v http://example.com
```

Curl should succeed connecting.
