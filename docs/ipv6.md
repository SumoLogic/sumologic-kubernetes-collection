# IPV6 Support

Supports EKS IPv6 clusters and any other k8’s cluster which has IPv6(Cluster)->IPv4(Internet) Egress communication



**Pre-requisites for EKS Cluster**

### 1. Configure IPv4 and IPv6 addresses for VPC and Subnets: 
The VPC and subnets that your cluster is using must have an IPv6 CIDR block. They must also have an IPv4 CIDR block assigned to them. This is because, even if you only want to use IPv6, a VPC still requires an IPv4 CIDR block for performing IPv6->IPv4 Egress communication.

```bash
aws ec2 associate-vpc-cidr-block \
    --vpc-id <your-vpc-id> \
    --amazon-provided-ipv6-cidr-block \
    --ipv6-cidr-block-network-border-group <your-network-border-group>
```

For detailed documentation on adding ipv6 and ipv4 CIDR to VPC. Please Refer, https://docs.aws.amazon.com/vpc/latest/userguide/add-ipv4-cidr.html






### 2. Ensure Amazon VPC CNI version 1.10.1 or later is deployed in cluster.
IP prefix delegation and ENABLE_IPv6 settings must be enabled. If you already deployed VPC-CNI Plugin while creating the cluster, these will be enabled automatically. If you adding the plugin to an existing cluster, please add the plugin and ensure these settings are enabled.

Create VPC-CNI addon:
```bash
aws eks create-addon --cluster-name my-cluster --addon-name vpc-cni --addon-version v1.20.0-eksbuild.1 \
--service-account-role-arn arn:aws:iam::111122223333:role/AmazonEKSVPCCNIRole
```
For more information, please refer: https://docs.aws.amazon.com/eks/latest/userguide/vpc-add-on-create.html

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

For more information, please refer: https://docs.aws.amazon.com/eks/latest/userguide/updating-an-add-on.html

### 3. Route table with ipv4 external route:
	Make sure that VPC’s Route table has a route from  IPv4(local) to Internet gateway .
Ex. 0.0.0.0/0→igw-XXX (Internet Gateway)

aws ec2 create-route \
    --route-table-id rtb-xxxxxxxx \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id igw-xxxxxxxx

For more information on adding route, please refer https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc-route-table.html#AddRoutes



