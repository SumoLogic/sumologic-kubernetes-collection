# Fargate

**NOTE: This is an experimental feature and it's not a subject of breaking changes policy.**

The following documentation assumes that you are using eksctl to manage Fargate cluster. Code snippets are using environment variables in
order to make them as generic and reusable.

- [Common operations](#common-operations)
  - [Set up Fargate Profile for Sumo Logic namespace](#set-up-fargate-profile-for-sumo-logic-namespace)
  - [Create EFS Volume](#create-efs-volume)
- [Metrics](#metrics)
  - [Persistence Disabled](#persistence-disabled)
  - [Persistence Enabled](#persistence-enabled)
    - [Create EFS access points for metric Pods](#create-efs-access-points-for-metric-pods)
    - [Create a security group to be used with mount targets](#create-a-security-group-to-be-used-with-mount-targets)
    - [Authorize ingress for security group](#authorize-ingress-for-security-group)
    - [Create mount targets for each pair of EFS access point and subnet](#create-mount-targets-for-each-pair-of-efs-access-point-and-subnet)
    - [Create sumo-metrics-pvc.yaml with PVC per access point](#create-sumo-metrics-pvcyaml-with-pvc-per-access-point)
    - [Create namespace if it doesn't exist already](#create-namespace-if-it-doesnt-exist-already)
    - [Apply sumo-metrics-pvc.yaml](#apply-sumo-metrics-pvcyaml)
  - [Install or upgrade collection](#install-or-upgrade-collection)
  - [Troubleshooting](#troubleshooting)
    - [Helm installation failed](#helm-installation-failed)
    - [otelcol-metrics Pods are in Pending state with Pod not supported on Fargate: volumes not supported error](#otelcol-metrics-pods-are-in-pending-state-with-pod-not-supported-on-fargate-volumes-not-supported-error)
      - [otelcol-metrics Pods are in Pending state with Output: Failed to resolve "fs-xxxxxxxx.efs.us-east-2.amazonaws.com" - check that your file system ID is correct, and ensure that the VPC has an EFS mount target for this file system ID. error](#otelcol-metrics-pods-are-in-pending-state-with-output-failed-to-resolve-fs-xxxxxxxxefsus-east-2amazonawscom---check-that-your-file-system-id-is-correct-and-ensure-that-the-vpc-has-an-efs-mount-target-for-this-file-system-id-error)
      - [Helm upgrade failed Error: UPGRADE FAILED: cannot patch "collection-sumologic-otelcol-metrics"](#helm-upgrade-failed-error-upgrade-failed-cannot-patch-collection-sumologic-otelcol-metrics)

Let's consider the following variables:

- `CLUSTER` - eksctl cluster name
- `PROFILE_NAME` - Fargate profile name related to Sumo Logic Collection to be (created and/or) used
- `NAMESPACE` - namespace where Sumo Logic Collection is going to be installed
- `AWS_REGION` - AWS region of the cluster
- `HELM_INSTALLATION_NAME` - Helm release name
- `SG_NAME` - Name of security group to be (created and/or) used
- `METRIC_PODS` - Maximum number of metric pods for the cluster. This value is needed to manually create Volumes

Let's consider the following example values:

```bash
export CLUSTER=sumologic-demo
export PROFILE_NAME=sumologic
export NAMESPACE=sumologic
export AWS_REGION=us-east-2
export HELM_INSTALLATION_NAME=collection
export SG_NAME=sumologic-collection
export METRIC_PODS=10
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

### Create EFS Volume

In order to use persistency you need to manually create EFS volume:

```bash
## Create EFS Volume
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
## Create EFS Volume
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

`EFS_ID` is going to be used in setting up Volumes for metric pods.

## Metrics

You can install metrics with or without persistence. See the following sections for more details:

- [Persistence disabled](#persistence-disabled)
- [Persistence enabled](#persistence-enabled)

### Persistence Disabled

To disable persistence, add the following configuration to `user-values.yaml`:

```yaml
metadata:
  persistence:
    enabled: false
```

**Note: This is going to disable persistence for both logs and metrics.**

### Persistence Enabled

If you want to keep persistence (which is default configuration), you need to manually create Volumes for the Metric Pods. We recommend to
create Persistent Volume Claims on the top of EFS Storage. In order to set up them, please apply the following steps:

#### Create EFS access points for metric Pods

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

#### Create mount targets for each pair of EFS access point and subnet

In order to be able to mount EFS access point within the subnet, the mount target should be created for them.

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

#### Create namespace if it doesn't exist already

```bash
## Create namespace if it doesn't exist already
kubectl create namespace "${NAMESPACE}"
```

#### Apply `sumo-metrics-pvc.yaml`

```bash
## Apply `sumo-metrics-pvc.yaml`
kubectl apply -f sumo-metrics-pvc.yaml -n "${NAMESPACE}"
```

### Install or upgrade collection

Disable Prometheus Node Exporter. As Amazon Fargate does not support Daemonsets, they won't be working correctly. There is no need to have
Node Exporter on Amazon Fargate as Amazon takes care of Nodes management. To disable Prometheus Node Exporter, please add the following
configuration to `user-values.yaml`:

```yaml
kube-prometheus-stack:
  nodeExporter:
    enabled: false
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

### Troubleshooting

#### Helm installation failed

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

#### otelcol-metrics Pods are in Pending state with `Pod not supported on Fargate: volumes not supported` error

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

#### otelcol-metrics Pods are in Pending state with `Output: Failed to resolve "fs-xxxxxxxx.efs.us-east-2.amazonaws.com" - check that your file system ID is correct, and ensure that the VPC has an EFS mount target for this file system ID.` error

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
- [Create mount targets for each pair of EFS access point and subnet](#create-mount-targets-for-each-pair-of-efs-access-point-and-subnet)

#### Helm upgrade failed `Error: UPGRADE FAILED: cannot patch "collection-sumologic-otelcol-metrics"`

If during helm upgrade you will see the following error:

```text
Error: UPGRADE FAILED: cannot patch "collection-sumologic-otelcol-metrics" with kind StatefulSet: StatefulSet.apps "collection-sumologic-otelcol-metrics" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' and 'minReadySeconds' are forbidden
```

It means that you have to manually remove Metrics Metadata Statefulset:

```bash
kubectl -n "${NAMESPACE}" delete statefulset -l "app=${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics"
```

This error may occur if you are switching persistence option for already installed Sumo Logic Kubernetes Collection.
