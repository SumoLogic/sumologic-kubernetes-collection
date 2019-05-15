#!/bin/bash
set -e

usage() {
  echo
  echo 'Usage:'
  echo '  setup.sh <endpoint> <access-id> <access-key> [collector-name]'
  echo
}

timestamp() {
  date +"%s"
}

create_host_collector()
{
  _P='{"collector":{"collectorType":"Hosted","name":"'
  _S='"}}'
  JSON="$_P$1$_S"
  COMMAND="curl -s -u $ACC_ID:$ACC_KEY -X POST -H Content-Type:application/json -d $JSON $SUMO_ENDPOINT/collectors"
  RESULT=$($COMMAND)
  set +e
  COLLECTOR_ID=$(echo $RESULT | jq -r '.collector.id')
  COLLECTOR_NAME=$(echo $RESULT | jq -r '.collector.name')
  set -e
  if [ ! -n "$COLLECTOR_ID" -o "null" == "$COLLECTOR_ID" ]; then
    echo 'Failed to create collector:';
    echo $RESULT
    exit -3;
  fi
  echo "Collector was created(id=$COLLECTOR_ID, name=$COLLECTOR_NAME)."
}

create_http_source()
{
  _P='{"source":{"sourceType":"HTTP","name":"'
  _S='","messagePerRequest":false,"multilineProcessingEnabled":false}}'
  JSON="$_P$1$_S"
  COMMAND="curl -s -u $ACC_ID:$ACC_KEY -X POST -H Content-Type:application/json -d $JSON $SUMO_ENDPOINT/collectors/$2/sources"
  RESULT=$($COMMAND)
  set +e
  SOURCE_URL=$(echo $RESULT | jq -r '.source.url')
  SOURCE_ID=$(echo $RESULT | jq -r '.source.id')
  SOURCE_NAME=$(echo $RESULT | jq -r '.source.name')
  set -e
  if [ ! -n "$SOURCE_URL" -o "null" == "$SOURCE_URL" ]; then
    echo 'Failed to create source:';
    echo $RESULT
    exit -4;
  fi
  echo "Source was created(id=$SOURCE_ID, name=$SOURCE_NAME)."
}

if [ -n "$1" ]; then
  SUMO_ENDPOINT=${1%/};
else
  echo '<endpoint> is missing.';
  usage;
  exit -1;
fi

if [ -n "$2" ]; then
  ACC_ID=$2;
else
  echo '<access-id> is missing.';
  usage;
  exit -1;
fi

if [ -n "$3" ]; then
  ACC_KEY=$3;
else
  echo '<access-key> is missing.';
  usage;
  exit -1;
fi

if [ -n "$4" ]; then
  COLLECTOR_NAME=$4;
else
  TIME=`timestamp`;
  COLLECTOR_NAME="kubernetes-$TIME";
fi

set +e
kubectl describe namespace sumologic &>/dev/null
retVal=$?
set -e
if [ $retVal -ne 0 ]; then
  echo "Creating namespace 'sumologic'..."
  kubectl create namespace sumologic
else
  echo "Namespace 'sumologic' exists, skip creating."
fi

set +e
echo "Creating secret 'metric-endpoints'..."
kubectl -n sumologic describe secret metric-endpoints &>/dev/null
retVal=$?
set -e
if [ $retVal -eq 0 ]; then
  echo "Secret 'sumologic::metric-endpoints' exists, abort."
  exit -2;
fi

echo "Creating collector '$COLLECTOR_NAME'..."
COLLECTOR_ID=
create_host_collector $COLLECTOR_NAME

echo "Creating sources in '$COLLECTOR_NAME'..."
SOURCE_URL=
create_http_source '(default)' $COLLECTOR_ID
ENDPOINT_METRICS="$SOURCE_URL"
SOURCE_URL=
create_http_source apiserver $COLLECTOR_ID
ENDPOINT_METRICS_APISERVER="$SOURCE_URL"
SOURCE_URL=
create_http_source kube-controller-manager $COLLECTOR_ID
ENDPOINT_METRICS_KUBE_CONTROLLER_MANAGER="$SOURCE_URL"
SOURCE_URL=
create_http_source kube-scheduler $COLLECTOR_ID
ENDPOINT_METRICS_KUBE_SCHEDULER="$SOURCE_URL"
SOURCE_URL=
create_http_source kube-state $COLLECTOR_ID
ENDPOINT_METRICS_KUBE_STATE="$SOURCE_URL"
SOURCE_URL=
create_http_source kubelet $COLLECTOR_ID
ENDPOINT_METRICS_KUBELET="$SOURCE_URL"
SOURCE_URL=
create_http_source node-exporter $COLLECTOR_ID
ENDPOINT_METRICS_NODE_EXPORTER="$SOURCE_URL"

kubectl -n sumologic create secret generic metric-endpoints \
  --from-literal=endpoint-metrics=$ENDPOINT_METRICS \
  --from-literal=endpoint-metrics-apiserver=$ENDPOINT_METRICS_APISERVER \
  --from-literal=endpoint-metrics-kube-controller-manager=$ENDPOINT_METRICS_KUBE_CONTROLLER_MANAGER \
  --from-literal=endpoint-metrics-kube-scheduler=$ENDPOINT_METRICS_KUBE_SCHEDULER \
  --from-literal=endpoint-metrics-kube-state=$ENDPOINT_METRICS_KUBE_STATE \
  --from-literal=endpoint-metrics-kubelet=$ENDPOINT_METRICS_KUBELET \
  --from-literal=endpoint-metrics-node-exporter=$ENDPOINT_METRICS_NODE_EXPORTER

echo "Applying deployment 'fluentd'..."
kubectl apply -f https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/fluentd-sumologic.yaml

echo "Done."
