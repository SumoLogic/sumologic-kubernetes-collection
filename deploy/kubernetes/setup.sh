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
  curl -s -u "$ACC_ID:$ACC_KEY" -X POST -H "Content-Type: application/json" -d $JSON "$SUMO_ENDPOINT/collectors" | jq -r '.collector.id'
}

create_http_source()
{
  _P='{"source":{"sourceType":"HTTP","name":"'
  _S='","messagePerRequest":false,"multilineProcessingEnabled":false}}'
  JSON="$_P$1$_S"
  curl -s -u "$ACC_ID:$ACC_KEY" -X POST -H "Content-Type: application/json" -d $JSON "$SUMO_ENDPOINT/collectors/$2/sources" | jq -r '.source.url'
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

echo "Creating collector '$COLLECTOR_NAME'..."
COLLECTOR_ID=`create_host_collector $COLLECTOR_NAME`
if [ ! -n "$COLLECTOR_ID" ]; then
  echo 'Failed to create collector, please check the endpoint and access id/key are correct.';
  exit -1;
fi
ENDPOINT_METRICS=`create_http_source '(default)' $COLLECTOR_ID`
ENDPOINT_METRICS_APISERVER=`create_http_source apiserver $COLLECTOR_ID`
ENDPOINT_METRICS_KUBE_CONTROLLER_MANAGER=`create_http_source kube-controller-manager $COLLECTOR_ID`
ENDPOINT_METRICS_KUBE_SCHEDULER=`create_http_source kube-scheduler $COLLECTOR_ID`
ENDPOINT_METRICS_KUBE_STATE=`create_http_source kube-state $COLLECTOR_ID`
ENDPOINT_METRICS_KUBELET=`create_http_source kubelet $COLLECTOR_ID`
ENDPOINT_METRICS_NODE_EXPORTER=`create_http_source node-exporter $COLLECTOR_ID`

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
echo "Creating secret 'sumologic'..."
kubectl -n sumologic describe secret sumologic &>/dev/null
retVal=$?
set -e
if [ $retVal -eq 0 ]; then
  echo "Deleting old secret 'sumologic'..."
  kubectl -n sumologic delete secret sumologic
fi
kubectl -n sumologic create secret generic sumologic \
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
