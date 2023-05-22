# Fargate

**Release Note: Generally Available (GA) Release of EKS Fargate.**

Supports EKS version 1.24 and above

The following documentation assumes that you are using eksctl to manage Fargate cluster. Code snippets are using environment variables in
order to make them as generic and reusable.

- [Common operations](#common-operations)
  - [Set up Fargate Profile for Sumo Logic namespace](#set-up-fargate-profile-for-sumo-logic-namespace)
  - [Create EFS File system](#create-efs-file-system)
- [Persistence (events/logs/metrics)](#persistence-eventslogsmetrics)
  - [Persistence Disabled](#persistence-disabled)
  - [Persistence Enabled](#persistence-enabled)
    - [Create EFS access points for events/logs/metrics Pods](#create-efs-access-points-for-eventslogsmetrics-pods)
    - [Create a security group to be used with mount targets](#create-a-security-group-to-be-used-with-mount-targets)
    - [Authorize ingress for security group](#authorize-ingress-for-security-group)
    - [Create mount targets in each AZ](#create-mount-targets-in-each-az-using-efs-access-points)
    - [Create sumo-metrics-pvc.yaml with PVC per access point](#create-sumo-metrics-pvcyaml-with-pvc-per-access-point)
    - [Create sumo-logs-pvc.yaml with PVC per access point](#create-sumo-logs-pvcyaml-with-pvc-per-access-point)
    - [Create sumo-events-pvc.yaml with PVC per access point](#create-sumo-events-pvcyaml-with-pvc-per-access-point)
- [Cloudwatch Logs Collection](#logs)
  - [Fluent-bit log router configuration](#fluent-bit-log-router)
    - [Prerequisites](#prerequisites)
    - [Configuration](#configuration)
  - [Cloudwatch logs collection](#cloudwatch-logs-collection)
    - [Authenticate with Cloudwatch](#authenticate-with-cloudwatch)
    - [Enable cloudwatch collection](#enable-cloudwatch-collection)
- [Install or upgrade collection](#install-or-upgrade-collection)
- [Troubleshooting](#troubleshooting)
  - [Helm installation failed](#helm-installation-failed)
  - [otelcol-metrics Pods are in Pending state with Pod not supported on Fargate: volumes not supported error](#otelcol-metrics-pods-are-in-pending-state-with-pod-not-supported-on-fargate-volumes-not-supported-error)
    - [otelcol-metrics Pods are in Pending state with Output: Failed to resolve "fs-xxxxxxxx.efs.us-east-2.amazonaws.com" - check that your file system ID is correct, and ensure that the VPC has an EFS mount target for this file system ID. error](#otelcol-metrics-pods-are-in-pending-state-with-output-failed-to-resolve-fs-xxxxxxxxefsus-east-2amazonawscom---check-that-your-file-system-id-is-correct-and-ensure-that-the-vpc-has-an-efs-mount-target-for-this-file-system-id-error)
    - [Helm upgrade failed Error: UPGRADE FAILED: cannot patch "collection-sumologic-otelcol-metrics"](#helm-upgrade-failed-error-upgrade-failed-cannot-patch-collection-sumologic-otelcol-metrics)
  - [AWS logging](#invalid-configmap)
  - [Invalid configuration](#invalid-cloudwatch-receiver-configuration)

Let's consider the following variables:

- `CLUSTER` - eksctl cluster name
- `PROFILE_NAME` - Fargate profile name related to Sumo Logic Collection to be (created and/or) used
- `NAMESPACE` - namespace where Sumo Logic Collection is going to be installed
- `AWS_REGION` - AWS region of the cluster
- `HELM_INSTALLATION_NAME` - Helm release name
- `SG_NAME` - Name of security group to be (created and/or) used
- `METRIC_PODS` - Maximum number of metric pods for the cluster. This value is needed to manually create Volumes
- `LOG_PODS` - Maximum number of log pods for the cluster. This value is needed to manually create Volumes
- `EVENT_PODS` - Maximum number of event pods for the cluster. This value is needed to manually create Volumes

Let's consider the following example values:

```bash
export CLUSTER=sumologic-demo
export PROFILE_NAME=sumologic
export NAMESPACE=sumologic
export AWS_REGION=us-east-2
export HELM_INSTALLATION_NAME=collection
export SG_NAME=sumologic-collection
export METRIC_PODS=10
export LOG_PODS=3
export EVENT_PODS=1
```

## Common operations

This section is going to gather all operations which may be common between different signals (metrics, logs, events and traces).

### Set up Fargate Profile for Sumo Logic namespace

In order to install our collection, please create fargate profile using
[Amazon Documentation](https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html#create-fargate-profile).

```bash
## Set up Fargate Profile for Sumo Logic namespace
eksctl create fargateprofile \
  --cluster "${CLUSTER}" \
  --name "${PROFILE_NAME}" \
  --namespace "${NAMESPACE}"
```

### Create EFS File system

In order to use persistency you need to manually create EFS volume:

```bash
## Create EFS File system
aws efs create-file-system \
  --encrypted \
  --performance-mode generalPurpose \
  --throughput-mode bursting \
  --tags Key=Name,Value=SumologicCollectionVolumes \
  --region "${AWS_REGION}"

export EFS_ID="$(
  aws efs describe-file-systems \
    --region="${AWS_REGION}" | \
    jq '.FileSystems[] |
      select(.Tags[].Key == "Name" and .Tags[].Value == "SumologicCollectionVolumes") |
      .FileSystemId' \
      --raw-output)"
```

The following snippet ensures that the Volume won't be duplicated:

```bash
## Create EFS File system
export EFS_ID="$(
  aws efs describe-file-systems \
    --region="${AWS_REGION}" | \
    jq '.FileSystems[] |
      select(.Tags[].Key == "Name" and .Tags[].Value == "SumologicCollectionVolumes") |
      .FileSystemId' \
      --raw-output)"

if [[ -z "${EFS_ID}" ]]; then
  aws efs create-file-system \
    --encrypted \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --tags Key=Name,Value=SumologicCollectionVolumes \
    --region "${AWS_REGION}"
  export EFS_ID="$(
    aws efs describe-file-systems \
      --region="${AWS_REGION}" | \
      jq '.FileSystems[] |
        select(.Tags[].Key == "Name" and .Tags[].Value == "SumologicCollectionVolumes") |
        .FileSystemId' \
        --raw-output)"
fi
```

`EFS_ID` is going to be used in setting up volumes for events, logs and metrics pods.

## Persistence (events/logs/metrics)

You can install events/logs/metrics with or without persistence. See the following sections for more details:

- [Persistence disabled](#persistence-disabled)
- [Persistence enabled](#persistence-enabled)

### Persistence Disabled

To disable persistence (metadata), add the following configuration to `user-values.yaml`:

```yaml
metadata:
  persistence:
    enabled: false
sumologic:
  logs:
    collector:
      otelcloudwatch:
        persistence:
          enabled: false
```

**Note: This is going to disable persistence for both logs and metrics.**

### Persistence Enabled

If you want to keep persistence (which is default configuration), you need to manually create Volumes for the events, logs and metrics Pods.
We recommend to create Persistent Volume Claims on the top of EFS Storage. In order to set up them, please apply the following steps:

#### Create EFS access points for events/logs/metrics Pods

[Dynamic provisioning](https://aws.amazon.com/blogs/containers/introducing-efs-csi-dynamic-provisioning/) of EFS access points is not
supported on Fargate pods

EFS Access Point is an entry point for an application. We recommend to create Access Points pointing to the directories using
`/${NAMESPACE}/${PVC_NAME}` schema.

You can create them using the following `bash` script:

```bash
## Create EFS access points for metric Pods
for (( counter=0; counter<"${METRIC_PODS}"; counter++ )); do
  FSAP_ID="$(
    aws efs describe-access-points \
      --region "${AWS_REGION}" |
    jq ".AccessPoints[] |
      select(.RootDirectory.Path == \"/sumologic/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter}\") |
      .AccessPointId" \
      --raw-output)"

  if [[ -z "${FSAP_ID}" ]]; then
    aws efs create-access-point \
        --file-system-id "${EFS_ID}" \
        --posix-user Uid=1000,Gid=1000 \
        --root-directory "Path=/${NAMESPACE}/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter},CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=777}" \
        --region "${AWS_REGION}"
  fi
done

## Create EFS access points for Log Pods
for (( counter=0; counter<"${LOG_PODS}"; counter++ )); do
  FSAP_ID="$(
    aws efs describe-access-points \
      --region "${AWS_REGION}" |
    jq ".AccessPoints[] |
      select(.RootDirectory.Path == \"/sumologic/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-log-${counter}\") |
      .AccessPointId" \
      --raw-output)"

  if [[ -z "${FSAP_ID}" ]]; then
    aws efs create-access-point \
        --file-system-id "${EFS_ID}" \
        --posix-user Uid=1000,Gid=1000 \
        --root-directory "Path=/${NAMESPACE}/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-log-${counter},CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=777}" \
        --region "${AWS_REGION}"
  fi
done

## Create EFS access points for Event Pods
for (( counter=0; counter<"${EVENT_PODS}"; counter++ )); do
  FSAP_ID="$(
    aws efs describe-access-points \
      --region "${AWS_REGION}" |
    jq ".AccessPoints[] |
      select(.RootDirectory.Path == \"/sumologic/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-events-${counter}\") |
      .AccessPointId" \
      --raw-output)"

  if [[ -z "${FSAP_ID}" ]]; then
    aws efs create-access-point \
        --file-system-id "${EFS_ID}" \
        --posix-user Uid=1000,Gid=1000 \
        --root-directory "Path=/${NAMESPACE}/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-events-${counter},CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=777}" \
        --region "${AWS_REGION}"
  fi
done
```

#### Create a security group to be used with mount targets

We recommend to create Sumo Logic specific Security Group. It is needed to authorize cluster to use EFS storage.

It can be done using the following `bash` script:

```bash
## Create a security group to be used with mount targets
export VPC_ID="$(
  aws ec2 describe-vpcs \
    --region "${AWS_REGION}" | \
    jq ".Vpcs[] |
      select(.Tags[]=={\"Key\": \"alpha.eksctl.io/cluster-name\", \"Value\": \"${CLUSTER}\"}) |
      .VpcId" \
    --raw-output)"

aws ec2 create-security-group \
  --description "Sumo Logic Collection for Fargate" \
  --group-name "${SG_NAME}" \
  --vpc-id "${VPC_ID}" \
  --region "${AWS_REGION}"
export SG_ID="$(
  aws ec2 describe-security-groups \
    --region "${AWS_REGION}" | \
    jq ".SecurityGroups[] |
      select(.GroupName == \"${SG_NAME}\") |
      .GroupId" \
      --raw-output)"
```

#### Authorize ingress for security group

After creating Security Group, the VPC network should be granted to access EFS port.

It can be done using the following `bash` script:

```bash
## Authorize ingress for security group
export CIDR_BLOCK="$(
  aws ec2 describe-vpcs \
    --region "${AWS_REGION}" | \
    jq ".Vpcs[] |
      select(.VpcId == \"${VPC_ID}\") |
      .CidrBlock" \
      --raw-output)"
aws ec2 authorize-security-group-ingress \
  --group-id "${SG_ID}" \
  --protocol tcp \
  --port 2049 \
  --region "${AWS_REGION}" \
  --cidr "${CIDR_BLOCK}"
```

#### Create mount targets in each AZ using EFS access points

In order to be able to mount EFS access point within the subnet, the mount target should be created for them.

_Note:_ You can only create one mount target per Availability Zone

It can be done using the following `bash` script:

```bash
## Create mount targets for each pair of EFS access point and subnet
export SUBNETS="$(
  aws ec2 describe-subnets \
    --region "${AWS_REGION}" | \
    jq ".Subnets[] |
      select(.Tags[]=={\"Key\": \"alpha.eksctl.io/cluster-name\", \"Value\": \"${CLUSTER}\"}) |
      .SubnetId" \
      --raw-output)"
for subnet in $(echo "${SUBNETS}"); do
    aws efs create-mount-target \
    --file-system-id "${EFS_ID}" \
    --subnet-id "${subnet}" \
    --security-group "${SG_ID}" \
    --region "${AWS_REGION}"
done
```

#### Create `sumo-metrics-pvc.yaml` with PVC per access point

After creation Access Points and ensuring that they have been authorized, the following Kubernetes storage objects have to be created:

- `StorageClass` which informs AWS to bind EFS Access Points with Kubernetes Persitence Volume objects
- `PersistentVolume` which is a Kubernetes representation of the EFS Access Point
- `PersistenceVolumeClaim` which is a user request to use the storage

The objects can be created using the following `bash` script:

```bash
## Create `sumo-metrics-pvc.yaml` with PVC per access point
echo "---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
volumeBindingMode: Immediate" | tee sumo-metrics-pvc.yaml

for (( counter=0; counter<$METRIC_PODS; counter++ )); do
  FSAP_ID="$(
    aws efs describe-access-points \
      --region "${AWS_REGION}" | \
      jq ".AccessPoints[] |
        select(.RootDirectory.Path == \"/${NAMESPACE}/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter}\") |
        .AccessPointId" \
        --raw-output)"

  echo "---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter}
  labels:
    app: ${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  claimRef:
    namespace: ${NAMESPACE}
    name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter}
  csi:
    driver: efs.csi.aws.com
    volumeHandle: ${EFS_ID}::${FSAP_ID}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter}
  namespace: ${NAMESPACE}
  labels:
    app: ${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi"
done | tee -a sumo-metrics-pvc.yaml
```

Create namespace if it doesn't exist already

```bash
## Create namespace if it doesn't exist already
kubectl create namespace "${NAMESPACE}"
```

Apply `sumo-metrics-pvc.yaml`

```bash
## Apply `sumo-metrics-pvc.yaml`
kubectl apply -f sumo-metrics-pvc.yaml -n "${NAMESPACE}"
```

#### Create `sumo-logs-pvc.yaml` with PVC per access point

The objects can be created using the following `bash` script:

```bash
## Create `sumo-logs-pvc.yaml` with PVC per access point
echo "---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
volumeBindingMode: Immediate" | tee sumo-logs-pvc.yaml

for (( counter=0; counter<$LOG_PODS; counter++ )); do
  FSAP_ID="$(
    aws efs describe-access-points \
      --region "${AWS_REGION}" | \
      jq ".AccessPoints[] |
        select(.RootDirectory.Path == \"/${NAMESPACE}/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-logs-${counter}\") |
        .AccessPointId" \
        --raw-output)"

  echo "---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-logs-${counter}
  labels:
    app: ${HELM_INSTALLATION_NAME}-sumologic-otelcol-logs
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  claimRef:
    namespace: ${NAMESPACE}
    name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-logs-${counter}
  csi:
    driver: efs.csi.aws.com
    volumeHandle: ${EFS_ID}::${FSAP_ID}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-logs-${counter}
  namespace: ${NAMESPACE}
  labels:
    app: ${HELM_INSTALLATION_NAME}-sumologic-otelcol-logs
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi"
done | tee -a sumo-logs-pvc.yaml
```

Apply `sumo-logs-pvc.yaml`

```bash
## Apply `sumo-logs-pvc.yaml`
kubectl apply -f sumo-logs-pvc.yaml -n "${NAMESPACE}"
```

#### Create `sumo-events-pvc.yaml` with PVC per access point

The objects can be created using the following `bash` script:

```bash
## Create `sumo-events-pvc.yaml` with PVC per access point
echo "---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
volumeBindingMode: Immediate" | tee sumo-events-pvc.yaml

for (( counter=0; counter<$EVENT_PODS; counter++ )); do
  FSAP_ID="$(
    aws efs describe-access-points \
      --region "${AWS_REGION}" | \
      jq ".AccessPoints[] |
        select(.RootDirectory.Path == \"/${NAMESPACE}/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-events-${counter}\") |
        .AccessPointId" \
        --raw-output)"

  echo "---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-events-${counter}
  labels:
    app: ${HELM_INSTALLATION_NAME}-sumologic-otelcol-events
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  claimRef:
    namespace: ${NAMESPACE}
    name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-events-${counter}
  csi:
    driver: efs.csi.aws.com
    volumeHandle: ${EFS_ID}::${FSAP_ID}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-events-${counter}
  namespace: ${NAMESPACE}
  labels:
    app: ${HELM_INSTALLATION_NAME}-sumologic-otelcol-events
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi"
done | tee -a sumo-events-pvc.yaml
```

Apply `sumo-events-pvc.yaml`

```bash
## Apply `sumo-events-pvc.yaml`
kubectl apply -f sumo-events-pvc.yaml -n "${NAMESPACE}"
```

Please verify that all the expected persistent volume claims (PVCs) have been created and `bound` to the volumes using the command below

```bash
## Get PVCs
kubectl get pvc -n "${NAMESPACE}"
```

## Logs

The following are some of the steps needed to setup and enable logs collection on Fargate

### Fluent-bit log router

#### Prerequisites

- An existing Fargate profile that specifies an existing Kubernetes namespace that you deploy Fargate pods to. For more information, see
  [Create a Fargate profile for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-create-profile)

- An existing
  [Fargate pod execution role](https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-sg-pod-execution-role)

Also, ensure that the following policy is attached to the EKS fargate pod execution role

```bash
cat >eks-logging-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy --policy-name eks-logging-policy --policy-document file://eks-logging-policy.json
aws iam attach-role-policy --role-name <eks-fargate-pod-execution-role> --policy-arn=arn:aws:iam::$account_id:policy/eks-logging-policy
```

#### Configuration

Amazon EKS on Fargate offers a built-in log router based on Fluent Bit. This means that you don't explicitly run a Fluent Bit container as a
sidecar, but Amazon runs it for you. All that you have to do is configure the log router.

The fargate log router manages the `Service` and `Input` sections. One needs to create a `ConfigMap` in a namespace called
`aws-observability` to enable log routing to cloudwatch, an example is shown below:

```yaml
# fluent-bit-fargate
## Please enter the appropriate CloudWatch log_group_name and log_stream_prefix
---
kind: Namespace
apiVersion: v1
metadata:
  name: aws-observability
  labels:
    aws-observability: enabled
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: aws-logging
  namespace: aws-observability
data:
  flb_log_cw: "true"
  filters.conf: |
    [FILTER]
        Name parser
        Match *
        Key_Name log
        Parser containerd
  parsers.conf: |
    [PARSER]
        Name         containerd
        Format       regex
        Regex        ^(?<time>[^ ]+) (?<stream>stdout|stderr|stdout) (?<logtag>[^ ]*) (?<log>.*)$
        Time_Key     time
        Time_Format  %Y-%m-%dT%H:%M:%S.%LZ
  output.conf: |
    [OUTPUT]
        Name cloudwatch_logs
        Match *
        region us-east-2
        log_group_name fluent-bit-cloudwatch
        log_stream_prefix from-fluent-bit-
        auto_create_group true
```

Apply the above ConfigMap using the command below:

```bash
## Apply `fluent-bit-fargate.yaml`
kubectl apply -f fluent-bit-fargate.yaml
```

You can stream logs from Fargate directly to Amazon CloudWatch, using the output plugin shown above. Cloudwatch is currently the only
supported output plugin in AWS Fluent Bit running on EKS fargate. Note that the log router setup depends on the prerequisites. Otherwise,
one might fail to enable [aws-logging](#invalid-configmap)

For more information on this refer to [fargate-logging](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html)

### Cloudwatch logs collection

After setting up AWS Fluent Bit to forward logs to cloudwatch, the next step is to setup and enable cloudwatch collection in the helm chart.
These together implement logs collection on EKS Fargate.

This involves the following:

- [Setup Cloudwatch authentication](#authenticate-with-cloudwatch)
- [Enable Clouwatch collection](#enable-cloudwatch-collection)

#### Authenticate with Cloudwatch

To configure the service account to use an IAM role (for authentication), follow the steps below

- Set your AWS account ID to an environment variable
- Set your cluster's OIDC identity provider to an environment variable
- Set the the service account

```bash
export account_id=$(aws sts get-caller-identity --query "Account" --output text)
export oidc_provider=$(aws eks describe-cluster --name $CLUSTER --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
export service_account=$HELM_INSTALLATION_NAME-sumologic-otelcol-logs-collector
```

Create a cloudwatch policy

```bash
cat >cloudwatch-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:GetLogEvents",
                "logs:ListTagsForResource"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:*:log-stream:*",
                "arn:aws:logs:*:*:destination:*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "logs:DescribeQueries",
                "logs:DescribeExportTasks",
                "logs:GetLogRecord",
                "logs:GetQueryResults",
                "logs:StopQuery",
                "logs:TestMetricFilter",
                "logs:DescribeQueryDefinitions",
                "logs:DescribeResourcePolicies",
                "logs:GetLogDelivery",
                "logs:DescribeDestinations",
                "logs:ListLogDeliveries",
                "logs:ListTagsLogGroup",
                "logs:GetDataProtectionPolicy",
                "s3:GetObject",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:DescribeSubscriptionFilters",
                "logs:StartQuery",
                "logs:Unmask",
                "logs:DescribeMetricFilters",
                "logs:FilterLogEvents",
                "logs:GetLogGroupFields",
                "logs:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy --policy-name cloudwatch-policy --policy-document file://cloudwatch-policy.json
```

Create a cloudwatch role

```bash
cat >trust-relationship.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$account_id:oidc-provider/$oidc_provider"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$oidc_provider:aud": "sts.amazonaws.com",
          "$oidc_provider:sub": "system:serviceaccount:$namespace:$service_account"
        }
      }
    }
  ]
}
EOF

aws iam create-role --role-name cloudwatch-role --assume-role-policy-document file://trust-relationship.json --description "my-role-description"
```

Attach the cloudwatch-role to the cloudwatch policy

```bash
aws iam attach-role-policy --role-name cloudwatch-role --policy-arn=arn:aws:iam::$account_id:policy/cloudwatch-policy
```

The above policy must have permissions to list, read and describe cloudwatch log groups and streams. For more on this please refer to
[access for CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/iam-identity-based-access-control-cwl.html)

#### Enable cloudwatch collection

Update the `user-values.yaml` to add the following annotation to the service account. Replace `account-id` and `my-role` with the
appropriate values. This configuration is also referenced in the step to [install the helm chart](#install-or-upgrade-collection)

```yaml
sumologic:
  logs:
    collector:
      ## https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/awscloudwatchreceiver
      otelcloudwatch:
        enabled: false
        roleArn: arn:aws:iam::${account_id}:role/cloudwatch-role
        ## Configure persistence for the cloudwatch collector
        persistence:
          enabled: true
        region: ${AWS_REGION}
        pollInterval: 1m
        logGroups:
          ## The log group name
          fluent-bit-cloudwatch:
            ## The log stream names and prefixes, can also be specified as
            ## names: []
            ## prefixes:
            ## - from-fluent-bit-prefix
            prefixes:
              - from-fluent-bit-prefix
            names:
              - from-fluent-bit-fullname.log
```

where `my-role` is the name of the role created while setting up [authentication](#authenticate-with-cloudwatch)

For more information on creating the appropriate roles and policies, please refer to
[service account IAM role](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)

After setting up cloudwatch logs, [install the helm chart](#install-or-upgrade-collection)

## Install or upgrade collection

Disable the Prometheus Node Exporter. As Amazon Fargate does not support Daemonsets, they won't be working correctly. There is no need to
have Node Exporter on Amazon Fargate as Amazon takes care of Node management. To disable the Prometheus Node Exporter and to enable log
collection, please add the following configuration to `user-values.yaml`:

```yaml
kube-prometheus-stack:
  nodeExporter:
    enabled: false
sumologic:
  logs:
    collector:
      otelcloudwatch:
        enabled: true
        roleArn: arn:aws:iam::${account_id}:role/cloudwatch-role
        region: <region>
        logGroups:
          fluent-bit-cloudwatch:
            prefixes:
              - from-fluent-bit-prefix
            names:
              - from-fluent-bit-fullname.log
```

```bash
helm upgrade \
    --install \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    -f user-values.yaml \
    "${HELM_INSTALLATION_NAME}" \
    sumologic/sumologic
```

## Troubleshooting

### Helm installation failed

If Helm installation failed on Fargate, the possible reason is missing or incorrect Fargate profile. Check Setup Job descripion:

```sh
$ kubectl -n "${NAMESPACE}" describe pod
...
Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  2m40s  default-scheduler  0/2 nodes are available: 2 node(s) had untolerated taint {eks.amazonaws.com/compute-type: fargate}. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.
```

If you see the above or similiar output, ensure that your fargate profile for `${NAMESPACE}` exists and is correct.

See [Set up Fargate Profile for Sumo Logic namespace](#set-up-fargate-profile-for-sumo-logic-namespace) for more information

### otelcol-metrics Pods are in Pending state with `Pod not supported on Fargate: volumes not supported` error

If otelcol-metrics Pods are in `Pending` state with the following error:

```sh
$ kubectl describe pod collection-sumologic-otelcol-metrics-0 -n sumologic
...
Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  7m11s  fargate-scheduler  Scheduling%!(EXTRA string=Pod not supported on Fargate: volumes not supported: file-storage not supported because: PVC file-storage-collection-sumologic-otelcol-metrics-0 not bound)
```

Please remove all Persistence Volume Claims related to metrics:

```
kubectl -n "${NAMESPACE}" delete pvc -l "app=${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics"
```

Then you can either [disable persistence](#persistence-disabled) or ensure that all steps from [persistence enabled](#persistence-enabled)
has been applied correctly.

After all, upgrade collection with new configuration and eventually remove metrics pods:

```sh
kubectl -n "${NAMESPACE}" delete pod -l "app=${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics"
```

### otelcol-metrics Pods are in Pending state with `Output: Failed to resolve "fs-xxxxxxxx.efs.us-east-2.amazonaws.com" - check that your file system ID is correct, and ensure that the VPC has an EFS mount target for this file system ID.` error

If otelcol-metrics Pods are in `Pending` state with the following error:

```sh
$ kubectl describe pod collection-sumologic-otelcol-metrics-0 -n sumologic
...
Events:
  Type     Reason           Age   From               Message
  ----     ------           ----  ----               -------
  Warning  LoggingDisabled  51s   fargate-scheduler  Logging%!(EXTRA string=Disabled logging because aws-logging configmap was not found. configmap "aws-logging" not found)
  Normal   Scheduled        1s    fargate-scheduler  Binding%!(EXTRA string=Successfully assigned %v to %v, string=sumologic/collection-sumologic-otelcol-metrics-0, string=fargate-ip-192-168-180-219.us-east-2.compute.internal)
  Warning  FailedMount      1s    kubelet            MountVolume.SetUp failed for volume "file-storage-collection-sumologic-otelcol-metrics-0" : rpc error: code = Internal desc = Could not mount "fs-xxxxxxxxxxxxxxxxx:/" at "/var/lib/kubelet/pods/48e15743-b526-4c2c-bd42-373330e77201/volumes/kubernetes.io~csi/file-storage-collection-sumologic-otelcol-metrics-0/mount": mount failed: exit status 1
Mounting command: mount
Mounting arguments: -t efs -o accesspoint=fsap-yyyyyyyyyyyyyyyyy,tls fs-xxxxxxxxxxxxxxxxx:/ /var/lib/kubelet/pods/48e15743-b526-4c2c-bd42-373330e77201/volumes/kubernetes.io~csi/file-storage-collection-sumologic-otelcol-metrics-0/mount
Output: Failed to resolve "fs-xxxxxxxxxxxxxxxxx.efs.us-east-2.amazonaws.com" - check that your file system ID is correct, and ensure that the VPC has an EFS mount target for this file system ID.
See https://docs.aws.amazon.com/console/efs/mount-dns-name for more detail.
Attempting to lookup mount target ip address using botocore. Failed to import necessary dependency botocore, please install botocore first.
```

Ensure that the following steps has been applied:

- [Create a security group to be used with mount targets](#create-a-security-group-to-be-used-with-mount-targets)
- [Authorize ingress for security group](#authorize-ingress-for-security-group)
- [Create mount targets in each AZ using EFS AP](#create-mount-targets-in-each-az-using-efs-access-points)

### Helm upgrade failed `Error: UPGRADE FAILED: cannot patch "collection-sumologic-otelcol-metrics"`

If during helm upgrade you will see the following error:

```text
Error: UPGRADE FAILED: cannot patch "collection-sumologic-otelcol-metrics" with kind StatefulSet: StatefulSet.apps "collection-sumologic-otelcol-metrics" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' and 'minReadySeconds' are forbidden
```

It means that you have to manually remove Metrics Metadata Statefulset:

```bash
kubectl -n "${NAMESPACE}" delete statefulset -l "app=${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics"
```

This error may occur if you are switching persistence option for already installed Sumo Logic Kubernetes Collection.

### Invalid ConfigMap

If Fluent Bit log router hasn't been setup correctly, you will see the warning below:

```text
Warning  LoggingDisabled  <unknown>  fargate-scheduler  Disabled logging because aws-logging configmap was not found. configmap "aws-logging" not found
```

### Invalid cloudwatch receiver configuration

If when cloudwatch logs collection is enabled, you see the following error in the logs

```
error    awscloudwatchreceiver@v0.76.1/logs.go:215    unable to retrieve logs from cloudwatch    {"kind": "receiver", "name": "awscloudwatch", "data_type" │
│ : "logs", "log group": "ameriprise-fargate-fluent", "error": "ResourceNotFoundException: The specified log group does not exist."}
```

It means that the cloudwatch receiver hasn't been configured correctly. Please ensure that the configuration follows this
[example format](#enable-cloudwatch-collection)
