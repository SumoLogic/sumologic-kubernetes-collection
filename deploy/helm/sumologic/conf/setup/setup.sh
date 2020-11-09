#!/bin/bash

# Fix URL to remove "v1" or "v1/"
export SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL%v1*}
# Support proxy for terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}
export NO_PROXY=${NO_PROXY:=""}

function remaining_fields() {
    local RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields/quota)"

    echo "${RESPONSE}" | jq '.remaining'
}

# Check if we'd have at least 10 fields remaining after additional fields
# would be created for the collection
function should_create_fields() {
    local REMAINING=$(remaining_fields)
    if [[ $(( REMAINING - {{ len .Values.sumologic.logs.fields }} )) -ge 10 ]] ; then
        return 0
    else
        return 1
    fi
}

cp /etc/terraform/{locals,main,providers,resources,variables,fields}.tf /terraform/
cd /terraform

COLLECTOR_NAME="{{- if .Values.sumologic.collectorName }}{{ .Values.sumologic.collectorName }}{{- else}}{{ .Values.sumologic.clusterName }}{{- end}}"

terraform init

# Sumo Logic fields
if should_create_fields ; then
    readonly CREATE_FIELDS=1
    readonly FIELDS_RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields | jq '.data[]' )"

    declare -ra FIELDS=({{ include "helm-toolkit.utils.joinListWithSpaces" .Values.sumologic.logs.fields }})
    for FIELD in "${FIELDS[@]}" ; do
        FIELD_ID=$( echo "${FIELDS_RESPONSE}" | jq -r "select(.fieldName == \"${FIELD}\") | .fieldId" )
        # Don't try to import non existing fields
        if [[ -z "${FIELD_ID}" ]]; then
            continue
        fi

        terraform import \
            -var="create_fields=1" \
            sumologic_field."${FIELD}" "${FIELD_ID}"
    done
else
    readonly CREATE_FIELDS=0
    echo "Couldn't automatically create fields"
    echo "You do not have enough field capacity to create the required fields automatically."
    echo "Please refer to https://help.sumologic.com/Manage/Fields to manually create the fields after you have removed unused fields to free up capacity."
fi

# Sumo Logic Collector and HTTP sources
terraform import sumologic_collector.collector "$COLLECTOR_NAME"

{{- $ctx := .Values -}}
{{- range $type, $sources := .Values.sumologic.sources }}
{{- if eq (include "terraform.sources.component_enabled" (dict "Context" $ctx "Type" $type)) "true" }}
{{- range $key, $source := $sources }}
{{- if eq (include "terraform.sources.to_create" (dict "Context" $ctx "Type" $type "Name" $key)) "true" }}
terraform import sumologic_http_source.{{ template "terraform.sources.name" (dict "Name" $key "Type" $type) }} "$COLLECTOR_NAME/{{ $source.name }}"
{{- end }}
{{- end }}
{{- end }}
{{- end }}

# Kubernetes Secret
terraform import kubernetes_secret.sumologic_collection_secret {{ .Release.Namespace }}/sumologic

# Apply planned changes
terraform apply -auto-approve \
    -var="create_fields=${CREATE_FIELDS}"

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=

bash /etc/terraform/custom.sh
