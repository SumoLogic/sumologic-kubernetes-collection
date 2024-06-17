#!/bin/bash

SUMOLOGIC_ACCESSID=${SUMOLOGIC_ACCESSID:=""}
readonly SUMOLOGIC_ACCESSID
SUMOLOGIC_ACCESSKEY=${SUMOLOGIC_ACCESSKEY:=""}
readonly SUMOLOGIC_ACCESSKEY
SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL:=""}
readonly SUMOLOGIC_BASE_URL

INTEGRATIONS_FOLDER_NAME="Sumo Logic Integrations"
MONITORS_FOLDER_NAME="Kubernetes"

if [ "${SUMOLOGIC_MONITORS_STATUS}" = "enabled" ]; then
  MONITORS_DISABLED="false"
else
  MONITORS_DISABLED="true"
fi

MONITORS_ROOT_ID="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/monitors/root | jq -r '.id' )"
readonly MONITORS_ROOT_ID

# verify if the integrations folder already exists
INTEGRATIONS_RESPONSE="$(curl -XGET -s -G \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/monitors/search \
        --data-urlencode "query=type:folder ${INTEGRATIONS_FOLDER_NAME}" | \
        jq '.[]' )"
readonly INTEGRATIONS_RESPONSE

INTEGRATIONS_FOLDER_ID="$( echo "${INTEGRATIONS_RESPONSE}" | \
        jq -r "select(.item.name == \"${INTEGRATIONS_FOLDER_NAME}\") | select(.item.parentId == \"${MONITORS_ROOT_ID}\") | .item.id" )"

# and create it if necessary
if [[ -z "${INTEGRATIONS_FOLDER_ID}" ]]; then
  INTEGRATIONS_FOLDER_ID="$(curl -XPOST -s \
              -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
              -H "Content-Type: application/json" \
              -d "{\"name\":\"${INTEGRATIONS_FOLDER_NAME}\",\"type\":\"MonitorsLibraryFolder\",\"description\":\"Monitors provided by the Sumo Logic integrations.\"}" \
              "${SUMOLOGIC_BASE_URL}"v1/monitors?parentId="${MONITORS_ROOT_ID}" | \
              jq -r " .id" )"
fi

# verify if the k8s monitors folder already exists
MONITORS_RESPONSE="$(curl -XGET -s -G \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/monitors/search \
        --data-urlencode "query=type:folder ${MONITORS_FOLDER_NAME}" | \
        jq '.[]' )"
readonly MONITORS_RESPONSE

MONITORS_FOLDER_ID="$( echo "${MONITORS_RESPONSE}" | \
        jq -r "select(.item.name == \"${MONITORS_FOLDER_NAME}\") | select(.item.parentId == \"${INTEGRATIONS_FOLDER_ID}\") | .item.id" )"
readonly MONITORS_FOLDER_ID

if [[ -z "${MONITORS_FOLDER_ID}" ]]; then
  # go to monitors directory
  cd /monitors || exit 2

  # Fall back to init -upgrade to prevent:
  # Error: Inconsistent dependency lock file
  terraform init -input=false || terraform init -input=false -upgrade

  # extract environment from SUMOLOGIC_BASE_URL
  # see: https://help.sumologic.com/docs/api/getting-started/#sumo-logic-endpoints-by-deployment-and-firewall-security
  SUMOLOGIC_ENV=$( echo "${SUMOLOGIC_BASE_URL}" | sed -E 's/https:\/\/.*(au|ca|de|eu|fed|in|jp|us2)\.sumologic\.com.*/\1/' )
  if [[ "${SUMOLOGIC_BASE_URL}" == "${SUMOLOGIC_ENV}" ]] ; then
    SUMOLOGIC_ENV="us1"
  fi

  TERRAFORM_ARGS=(
    -auto-approve
    -var="access_id=${SUMOLOGIC_ACCESSID}"
    -var="access_key=${SUMOLOGIC_ACCESSKEY}"
    -var="environment=${SUMOLOGIC_ENV}"
    -var="folder=${MONITORS_FOLDER_NAME}"
    -var="folder_parent_id=${INTEGRATIONS_FOLDER_ID}"
    -var="monitors_disabled=${MONITORS_DISABLED}"
  )

  if [ -z ${SUMOLOGIC_MONITORS_NOTIFICATIONS_RECIPIENTS+x} ]; then
    NOTIFICATIONS_CONTENT="subject=\"Monitor Alert: {{ printf `{{TriggerType}}` }} on {{ printf `{{Name}}` }}\",message_body=\"Triggered {{ printf `{{TriggerType}}` }} alert on {{ printf `{{Name}}` }}: {{ printf `{{QueryURL}}` }}\""
    NOTIFICATIONS_SETTINGS="recipients=${SUMOLOGIC_MONITORS_NOTIFICATIONS_RECIPIENTS},connection_type=\"Email\",time_zone=\"UTC\""
    TERRAFORM_ARGS+=(
      -var="email_notifications_critical=[{${NOTIFICATIONS_SETTINGS},${NOTIFICATIONS_CONTENT},run_for_trigger_types=[\"Critical\", \"ResolvedCritical\"]}]"
      -var="email_notifications_warning=[{${NOTIFICATIONS_SETTINGS},${NOTIFICATIONS_CONTENT},run_for_trigger_types=[\"Warning\", \"ResolvedWarning\"]}]"
      -var="email_notifications_missingdata=[{${NOTIFICATIONS_SETTINGS},${NOTIFICATIONS_CONTENT},run_for_trigger_types=[\"MissingData\", \"ResolvedMissingData\"]}]"
    )
  fi

  TF_LOG_PROVIDER=DEBUG terraform apply "${TERRAFORM_ARGS[@]}" \
      || { echo "Error during applying Terraform monitors."; exit 1; }
else
  echo "The monitors have been already installed in ${MONITORS_FOLDER_NAME}."
  echo "You can (re)install them manually with:"
  echo "https://github.com/SumoLogic/terraform-sumologic-sumo-logic-monitor/tree/main/monitor_packages/kubernetes"
fi
