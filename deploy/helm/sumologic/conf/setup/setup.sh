#!/bin/bash

readonly DEBUG_MODE=${DEBUG_MODE:="false"}
readonly DEBUG_MODE_ENABLED_FLAG="true"
readonly TEST_PVC_FILE="test-pvc-ss.yaml"
readonly TEST_PVC_STATEFULSET="pvc-nginx"
readonly TEST_PVC_NAMESPACE="test-pvc"
readonly TEST_PVC_STATEFULSET_CONFIG="apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx
  serviceName: \"nginx\"
  replicas: 1
  minReadySeconds: 10 # by default is 0
  template:
    metadata:
      labels:
        app: nginx
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ \"ReadWriteOnce\" ]
      resources:
        requests:
          storage: 1Gi
"

# Let's compare the variables ignoring the case with help of ${VARIABLE,,} which makes the string lowercased
# so that we don't have to deal with True vs true vs TRUE
if [[ ${DEBUG_MODE,,} == "${DEBUG_MODE_ENABLED_FLAG}" ]]; then
    echo "Entering the debug mode with continuous sleep. No setup will be performed."
    echo "Please exec into the setup container and run the setup.sh by hand or set the sumologic.setup.debug=false and reinstall."

    while true; do
        sleep 10
        DATE=$(date)
        echo "${DATE} Sleeping in the debug mode..."
    done
fi

function fix_sumo_base_url() {
  local BASE_URL
  BASE_URL=${SUMOLOGIC_BASE_URL}

  if [[ "${BASE_URL}" =~ ^\s*$ ]]; then
    BASE_URL="https://api.sumologic.com/api/"
  fi

  # shellcheck disable=SC2312
  OPTIONAL_REDIRECTION="$(curl -XGET -s -o /dev/null -D - \
          -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
          "${BASE_URL}"v1/collectors \
          | grep -Fi location )"

  if [[ ! ${OPTIONAL_REDIRECTION} =~ ^\s*$ ]]; then
    BASE_URL=$( echo "${OPTIONAL_REDIRECTION}" | sed -E 's/.*: (https:\/\/.*(au|ca|de|eu|fed|in|jp|us2)?\.sumologic\.com\/api\/).*/\1/' )
  fi

  BASE_URL=${BASE_URL%v1*}

  echo "${BASE_URL}"
}

SUMOLOGIC_BASE_URL=$(fix_sumo_base_url)
export SUMOLOGIC_BASE_URL
# Support proxy for Terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}
export NO_PROXY=${NO_PROXY:=""}

function get_remaining_fields() {
    local RESPONSE
    RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields/quota)"
    readonly RESPONSE

    echo "${RESPONSE}"
}

# Check if we'd have at least 10 fields remaining after additional fields
# would be created for the collection
function should_create_fields() {
    local RESPONSE
    RESPONSE=$(get_remaining_fields)
    readonly RESPONSE

    if ! jq -e <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        return 1
    fi

    if ! jq -e '.remaining' <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        return 1
    fi

    local REMAINING
    REMAINING=$(jq -e '.remaining' <<< "${RESPONSE}")
    readonly REMAINING
    if [[ $(( REMAINING - {{ len .Values.sumologic.logs.fields }} )) -ge 10 ]] ; then
        return 0
    else
        return 1
    fi
}

function pvc_test_create_statefulset() {
    kubectl create namespace ${TEST_PVC_NAMESPACE}
    echo "${TEST_PVC_STATEFULSET_CONFIG}" > ${TEST_PVC_FILE}

    kubectl -n ${TEST_PVC_NAMESPACE} apply -f ${TEST_PVC_FILE}
    if [[ $? -eq 0 ]]; then
      return 0
    else
      echo "Creating statefulset failed"
      pvc_test_cleanup
      exit 1
    fi
}

function pvc_test_check() {
    local pending_pvcs
    pending_pvcs=$(kubectl -n ${TEST_PVC_NAMESPACE} get pvc | grep -c  "Pending")
    readonly pending_pvcs

    if [[ $? -ne 0 ]]; then
        echo "Querying pvcs failed"
        exit 1
    else
        return $pending_pvcs
    fi
}

function pvc_test_cleanup() {
    kubectl delete all --all -n ${TEST_PVC_NAMESPACE}
    kubectl delete pvc --all -n ${TEST_PVC_NAMESPACE}
    rm ${TEST_PVC_FILE}
}

function can_create_pvc() {
    pvc_test_create_statefulset
    sleep 30
    pvc_test_check
    if [[ $? -ne 0 ]]; then
        echo "PVC could not be created automatically"
        exit 1
    else
        echo "PVC can be created automatically"
        return 0
    fi
}

cp /etc/terraform/{locals,main,providers,resources,variables,fields}.tf /terraform/
cd /terraform || exit 1

# Fall back to init -upgrade to prevent:
# Error: Inconsistent dependency lock file
terraform init -input=false -get=false || terraform init -input=false -upgrade

# Sumo Logic fields
if should_create_fields ; then
    readonly CREATE_FIELDS=1
    # shellcheck disable=SC2312
    FIELDS_RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields | jq '.data[]' )"
    readonly FIELDS_RESPONSE

    declare -ra FIELDS=({{ include "helm-toolkit.utils.joinListWithSpaces" .Values.sumologic.logs.fields }})
    for FIELD in "${FIELDS[@]}" ; do
        FIELD_ID=$( echo "${FIELDS_RESPONSE}" | jq -r "select(.fieldName | ascii_downcase == \"${FIELD}\") | .fieldId" )
        # Don't try to import non existing fields
        if [[ -z "${FIELD_ID}" ]]; then
            continue
        fi

        terraform import \
            -var="create_fields=1" \
            sumologic_field."${FIELD}"[0] "${FIELD_ID}"
    done
else
    readonly CREATE_FIELDS=0
    echo "Couldn't automatically create fields"
    echo "You do not have enough field capacity to create the required fields automatically."
    echo "Please refer to https://help.sumologic.com/docs/manage/fields/ to manually create the fields after you have removed unused fields to free up capacity."
fi

readonly COLLECTOR_NAME="{{ template "terraform.collector.name" . }}"

# Sumo Logic Collector and HTTP sources
# Only import sources when collector exists.
if terraform import sumologic_collector.collector "${COLLECTOR_NAME}"; then
true  # prevent to render empty if; then
{{- $ctx := .Values -}}
{{- range $type, $sources := .Values.sumologic.collector.sources }}
{{- if eq (include "terraform.sources.component_enabled" (dict "Values" $ctx "Type" $type)) "true" }}
{{- range $key, $source := $sources }}
{{- if eq (include "terraform.sources.to_create" (dict "Context" $ctx "Type" $type "Name" $key)) "true" }}
terraform import sumologic_http_source.{{ template "terraform.sources.name" (dict "Name" $key "Type" $type) }} "${COLLECTOR_NAME}/{{ $source.name }}"
{{- end }}
{{- end }}
{{- else if and (eq $type "metrics") $ctx.sumologic.traces.enabled }}
{{- /*
If traces are enabled and metrics are disabled, create default metrics source anyway
*/}}
{{- if hasKey $sources "default" }}
terraform import sumologic_http_source.{{ template "terraform.sources.name" (dict "Name" "default" "Type" $type) }} "${COLLECTOR_NAME}/{{ $sources.default.name }}"
{{- end }}
{{- end }}
{{- end }}
fi

# Kubernetes Secret
terraform import kubernetes_secret.sumologic_collection_secret {{ template "terraform.secret.fullname" . }}

# Apply planned changes
TF_LOG_PROVIDER=DEBUG terraform apply \
    -auto-approve \
    -var="create_fields=${CREATE_FIELDS}" \
    || { echo "Error during applying Terraform changes"; exit 1; }

# Setup Sumo Logic monitors if enabled
{{- if .Values.sumologic.setup.monitors.enabled }}
bash /etc/terraform/monitors.sh
{{- else }}
echo "Installation of the Sumo Logic monitors is disabled."
echo "You can install them manually later with:"
echo "https://github.com/SumoLogic/terraform-sumologic-sumo-logic-monitor/tree/main/monitor_packages/kubernetes"
{{- end }}

# Setup Sumo Logic dashboards if enabled
{{- if .Values.sumologic.setup.dashboards.enabled }}
bash /etc/terraform/dashboards.sh
{{- else }}
echo "Installation of the Sumo Logic dashboards is disabled."
echo "You can install them manually later with:"
echo "https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app"
{{- end }}

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=

bash /etc/terraform/custom.sh

{{- if (or .Values.metadata.persistence.enabled (or .Values.sumologic.events.persistence.enabled .Values.sumologic.logs.collector.otelcloudwatch.persistence.enabled)) }}
can_create_pvc
pvc_test_cleanup > /dev/null
{{- end }}
