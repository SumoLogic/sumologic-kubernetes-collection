#!/bin/bash

readonly DEBUG_MODE=${DEBUG_MODE:="false"}
readonly DEBUG_MODE_ENABLED_FLAG="true"

# Let's compare the variables ignoring the case with help of ${VARIABLE,,} which makes the string lowercased
# so that we don't have to deal with True vs true vs TRUE
if [[ ${DEBUG_MODE,,} == ${DEBUG_MODE_ENABLED_FLAG} ]]; then
    echo "Entering the debug mode with continuous sleep. No setup will be performed."
    echo "Please exec into the setup container and run the setup.sh by hand or set the sumologic.setup.debug=false and reinstall."

    while true; do
        sleep 10
        echo "$(date) Sleeping in the debug mode..."
    done
fi

# Fix URL to remove "v1" or "v1/"
export SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL%v1*}
# Support proxy for Terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}
export NO_PROXY=${NO_PROXY:=""}

function get_remaining_fields() {
    local RESPONSE
    readonly RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields/quota)"

    echo "${RESPONSE}"
}

# Check if we'd have at least 10 fields remaining after additional fields
# would be created for the collection
function should_create_fields() {
    local RESPONSE
    readonly RESPONSE=$(get_remaining_fields)

    if ! jq -e <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        return 1
    fi

    if ! jq -e '.remaining' <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        return 1
    fi

    local REMAINING
    readonly REMAINING=$(jq -e '.remaining' <<< "${RESPONSE}")
    if [[ $(( REMAINING - {{ len .Values.sumologic.logs.fields }} )) -ge 10 ]] ; then
        return 0
    else
        return 1
    fi
}

cp /etc/terraform/{locals,main,providers,resources,variables,fields}.tf /terraform/
cd /terraform || exit 1

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

readonly COLLECTOR_NAME="{{ template "terraform.collector.name" . }}"

# Sumo Logic Collector and HTTP sources
# Only import sources when collector exists.
if terraform import sumologic_collector.collector "${COLLECTOR_NAME}"; then
{{- $ctx := .Values -}}
{{- range $type, $sources := .Values.sumologic.collector.sources }}
{{- if eq (include "terraform.sources.component_enabled" (dict "Context" $ctx "Type" $type)) "true" }}
{{- range $key, $source := $sources }}
{{- if eq (include "terraform.sources.to_create" (dict "Context" $ctx "Type" $type "Name" $key)) "true" }}
terraform import sumologic_http_source.{{ template "terraform.sources.name" (dict "Name" $key "Type" $type) }} "${COLLECTOR_NAME}/{{ $source.name }}"
{{- end }}
{{- end }}
{{- end }}
{{- end }}
fi

# Kubernetes Secret
terraform import kubernetes_secret.sumologic_collection_secret {{ template "terraform.secret.fullname" . }}

# Apply planned changes
terraform apply -auto-approve \
    -var="create_fields=${CREATE_FIELDS}" \
    || { echo "Error during applying Terraform changes"; exit 1; }

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=

bash /etc/terraform/custom.sh
