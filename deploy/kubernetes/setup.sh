#!/bin/bash
set -e

usage() {
  echo
  echo 'Usage:'
  echo '  setup.sh [-c collector-name] [-k cluster-name] <endpoint> <access-id> <access-key>'
  echo
}

timestamp() {
  date +"%s"
}

create_host_collector()
{
  _P='{"collector":{"collectorType":"Hosted","name":"'
  _M='","fields":{"cluster":"'
  _S='"}}}'
  JSON="$_P$1$_M$2$_S"
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

while getopts c:k:n: option
do
 case "${option}"
 in
 c) COLLECTOR_NAME=${OPTARG};;
 k) CLUSTER_NAME=${OPTARG};;
 n) NAMESPACE=${OPTARG};;
 esac
done
shift "$(($OPTIND -1))"

TIME=`timestamp`;

if [ -z $COLLECTOR_NAME ]; then
  if [ -z $SUMO_COLLECTOR_NAME ]; 
  then
    COLLECTOR_NAME="kubernetes-$TIME";
  else
    COLLECTOR_NAME=$SUMO_COLLECTOR_NAME;
  fi
fi

if [ -z $CLUSTER_NAME ]; then
  if [ -z $KUBERNETES_CLUSTER_NAME ]
  then
    CLUSTER_NAME="kubernetes-$TIME";
  else
    CLUSTER_NAME=$KUBERNETES_CLUSTER_NAME
  fi
fi

if [ -z $NAMESPACE]; then
  if [ -z $SUMO_NAMESPACE ]
  then
    NAMESPACE="sumologic"
  else
    NAMESPACE=$SUMO_NAMESPACE
  fi
fi

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

set +e
kubectl describe namespace $NAMESPACE &>/dev/null
retVal=$?
set -e
if [ $retVal -ne 0 ]; then
  echo "Creating namespace '$NAMESPACE'..."
  kubectl create namespace $NAMESPACE
else
  echo "Namespace 'sumologic' exists, skip creating."
fi

set +e
echo "Checking for secret 'sumologic'..."
kubectl -n $NAMESPACE describe secret sumologic &>/dev/null
retVal=$?
set -e
if [ $retVal -eq 0 ]; then
  echo "Secret '${NAMESPACE}::sumologic' exists, abort."
  exit -2;
fi

echo "Creating collector '$COLLECTOR_NAME' for cluster $CLUSTER_NAME..."
COLLECTOR_ID=
create_host_collector $COLLECTOR_NAME $CLUSTER_NAME

echo "Creating sources in '$COLLECTOR_NAME'..."
SOURCE_URL=
create_http_source '(default-metrics)' $COLLECTOR_ID
ENDPOINT_METRICS="$SOURCE_URL"
SOURCE_URL=
create_http_source apiserver-metrics $COLLECTOR_ID
ENDPOINT_METRICS_APISERVER="$SOURCE_URL"
SOURCE_URL=
create_http_source kube-controller-manager-metrics $COLLECTOR_ID
ENDPOINT_METRICS_KUBE_CONTROLLER_MANAGER="$SOURCE_URL"
SOURCE_URL=
create_http_source kube-scheduler-metrics $COLLECTOR_ID
ENDPOINT_METRICS_KUBE_SCHEDULER="$SOURCE_URL"
SOURCE_URL=
create_http_source kube-state-metrics $COLLECTOR_ID
ENDPOINT_METRICS_KUBE_STATE="$SOURCE_URL"
SOURCE_URL=
create_http_source kubelet-metrics $COLLECTOR_ID
ENDPOINT_METRICS_KUBELET="$SOURCE_URL"
SOURCE_URL=
create_http_source node-exporter-metrics $COLLECTOR_ID
ENDPOINT_METRICS_NODE_EXPORTER="$SOURCE_URL"
SOURCE_URL=
create_http_source logs $COLLECTOR_ID
ENDPOINT_LOGS="$SOURCE_URL"
SOURCE_URL=
create_http_source events $COLLECTOR_ID
ENDPOINT_EVENTS="$SOURCE_URL"

kubectl -n $NAMESPACE create secret generic sumologic \
  --from-literal=endpoint-metrics=$ENDPOINT_METRICS \
  --from-literal=endpoint-metrics-apiserver=$ENDPOINT_METRICS_APISERVER \
  --from-literal=endpoint-metrics-kube-controller-manager=$ENDPOINT_METRICS_KUBE_CONTROLLER_MANAGER \
  --from-literal=endpoint-metrics-kube-scheduler=$ENDPOINT_METRICS_KUBE_SCHEDULER \
  --from-literal=endpoint-metrics-kube-state=$ENDPOINT_METRICS_KUBE_STATE \
  --from-literal=endpoint-metrics-kubelet=$ENDPOINT_METRICS_KUBELET \
  --from-literal=endpoint-metrics-node-exporter=$ENDPOINT_METRICS_NODE_EXPORTER \
  --from-literal=endpoint-logs=$ENDPOINT_LOGS \
  --from-literal=endpoint-events=$ENDPOINT_EVENTS

echo "Applying deployment 'fluentd'..."
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/fluentd-sumologic.yaml.tmpl | \
sed 's/\$NAMESPACE'"/$NAMESPACE/g" | \
kubectl -n $NAMESPACE apply -f -

echo "Done."
