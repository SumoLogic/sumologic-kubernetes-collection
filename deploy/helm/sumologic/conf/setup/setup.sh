#!/bin/bash

# Fix URL to remove "v1" or "v1/"
export SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL%v1*}
# Support proxy for terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}
export NO_PROXY=${NO_PROXY:=""}

function remaining_fields() {
    readonly RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields/quota)"

    echo "${RESPONSE}" | jq '.remaining'
}

mkdir /terraform/fields/
cp /etc/terraform/{locals,main,providers,resources,variables}.tf /terraform/
cp /etc/terraform/{main_fields,fields}.tf /terraform/fields/
cd /terraform

COLLECTOR_NAME="{{- if .Values.sumologic.collectorName }}{{ .Values.sumologic.collectorName }}{{- else}}{{ .Values.sumologic.clusterName }}{{- end}}"

terraform init

# Sumo Collector and HTTP sources
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

terraform apply -auto-approve

# Fields
#
# Check if we have at least 10 fields remaining after we would
# create 8 additional fields for the collection
readonly REMAINING=$(remaining_fields)
if [[ $(( REMAINING - 8 )) -ge -10 ]] ; then
    echo "Creating fields..."
    ( cd fields && terraform destroy -auto-approve )
else
    printf "Couldn't automatically create fields\n"
    printf "There's only %s remaining and collection requires at least 8\n" "${REMAINING}"
fi

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=

bash /etc/terraform/custom.sh
