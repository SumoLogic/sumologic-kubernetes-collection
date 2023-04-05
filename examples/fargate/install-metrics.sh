#!/usr/bin/env bash

export CLUSTER=sumologic-demo
export PROFILE_NAME=sumologic
export NAMESPACE=sumologic
export AWS_REGION=us-east-2
export HELM_INSTALLATION_NAME=collection
export SG_NAME=sumologic-collection
export METRIC_PODS=10

## Set up Fargate Profile for Sumo Logic namespace
eksctl create fargateprofile \
  --cluster "${CLUSTER}" \
  --name "${PROFILE_NAME}" \
  --namespace "${NAMESPACE}"

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

## Create EFS access points for metric Pods
for (( counter=0; counter<METRIC_PODS; counter++ )); do
  FSAP_ID="$(
    aws efs describe-access-points \
      --region "${AWS_REGION}" | 
    jq ".AccessPoints[] | 
      select(.RootDirectory.Path == \"/sumologic/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter}\") |
      .AccessPointId" \
      --raw-output)" || true

  if [[ -z "${FSAP_ID}" ]]; then
    aws efs create-access-point \
        --file-system-id "${EFS_ID}" \
        --posix-user Uid=1000,Gid=1000 \
        --root-directory "Path=/${NAMESPACE}/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter},CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=777}" \
        --region "${AWS_REGION}"
  fi
done

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

## Create mount targets for each pair of EFS access point and subnet
export SUBNETS="$(
  aws ec2 describe-subnets \
    --region "${AWS_REGION}" | \
    jq ".Subnets[] |
      select(.Tags[]=={\"Key\": \"alpha.eksctl.io/cluster-name\", \"Value\": \"${CLUSTER}\"}) |
      .SubnetId" \
      --raw-output)"
for subnet in ${SUBNETS}; do
    aws efs create-mount-target \
    --file-system-id "${EFS_ID}" \
    --subnet-id "${subnet}" \
    --security-group "${SG_ID}" \
    --region "${AWS_REGION}"
done

## Create `sumo-metrics-pvc.yaml` with PVC per access point
echo "---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
volumeBindingMode: Immediate" | tee sumo-metrics-pvc.yaml

for (( counter=0; counter<METRIC_PODS; counter++ )); do
  FSAP_ID="$(
    aws efs describe-access-points \
      --region "${AWS_REGION}" | \
      jq ".AccessPoints[] |
        select(.RootDirectory.Path == \"/${NAMESPACE}/file-storage-${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics-${counter}\") |
        .AccessPointId" \
        --raw-output)" || true

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
  labels:
    app: ${HELM_INSTALLATION_NAME}-sumologic-otelcol-metrics
  namespace: ${NAMESPACE}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi"
done | tee -a sumo-metrics-pvc.yaml


## Create namespace if it doesn't exist already
kubectl create namespace "${NAMESPACE}"

## Apply `sumo-metrics-pvc.yaml`
kubectl apply -f sumo-metrics-pvc.yaml -n "${NAMESPACE}"
