#!/bin/bash

SUMOLOGIC_ACCESSID=${SUMOLOGIC_ACCESSID:=""}
readonly SUMOLOGIC_ACCESSID
SUMOLOGIC_ACCESSKEY=${SUMOLOGIC_ACCESSKEY:=""}
readonly SUMOLOGIC_ACCESSKEY
SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL:=""}
readonly SUMOLOGIC_BASE_URL

INTEGRATIONS_FOLDER_NAME="Sumo Logic Integrations"
K8S_FOLDER_NAME="Kubernetes"
K8S_APP_UUID="162ceac7-166a-4475-8427-65e170ae9837"

function load_dashboards_folder_id() {
  local ADMIN_FOLDER_JOB_ID
  ADMIN_FOLDER_JOB_ID="$(curl -XGET -s \
          -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
          -H "isAdminMode: true" \
          "${SUMOLOGIC_BASE_URL}"v2/content/folders/adminRecommended | jq '.id' | tr -d '"' )"
  readonly ADMIN_FOLDER_JOB_ID

  local ADMIN_FOLDER_JOB_STATUS
  ADMIN_FOLDER_JOB_STATUS="InProgress"
  while [ "${ADMIN_FOLDER_JOB_STATUS}" = "InProgress" ]; do
    ADMIN_FOLDER_JOB_STATUS="$(curl -XGET -s \
          -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
          "${SUMOLOGIC_BASE_URL}"v2/content/folders/adminRecommended/"${ADMIN_FOLDER_JOB_ID}"/status | jq '.status' | tr -d '"' )"

    sleep 1
  done

  if [ "${ADMIN_FOLDER_JOB_STATUS}" != "Success" ]; then
    echo "Could not fetch data from the \"Admin Recommended\" content folder. The K8s Dashboards won't be installed."
    echo "You can still install them manually:"
    echo "https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app"
    exit 1
  fi

  local ADMIN_FOLDER
  ADMIN_FOLDER="$(curl -XGET -s \
          -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
          -H "isAdminMode: true" \
          "${SUMOLOGIC_BASE_URL}"v2/content/folders/adminRecommended/"${ADMIN_FOLDER_JOB_ID}"/result )"
  readonly ADMIN_FOLDER

  local ADMIN_FOLDER_CHILDREN
  ADMIN_FOLDER_CHILDREN="$( echo "${ADMIN_FOLDER}" | jq '.children[]')"
  readonly ADMIN_FOLDER_CHILDREN

  local ADMIN_FOLDER_ID
  ADMIN_FOLDER_ID="$( echo "${ADMIN_FOLDER}" | jq '.id' | tr -d '"')"
  readonly ADMIN_FOLDER_ID

  INTEGRATIONS_FOLDER_ID="$( echo "${ADMIN_FOLDER_CHILDREN}" | \
            jq -r "select(.name == \"${INTEGRATIONS_FOLDER_NAME}\") | .id" )"

  if [[ -z "${INTEGRATIONS_FOLDER_ID}" ]]; then
    INTEGRATIONS_FOLDER_ID="$(curl -XPOST -s \
            -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
            -H "isAdminMode: true" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"${INTEGRATIONS_FOLDER_NAME}\",\"parentId\":\"${ADMIN_FOLDER_ID}\",\"description\":\"Content provided by the Sumo Logic integrations.\"}" \
            "${SUMOLOGIC_BASE_URL}"v2/content/folders | \
            jq -r " .id" )"
  fi

  local INTEGRATIONS_FOLDER_CHILDREN
  INTEGRATIONS_FOLDER_CHILDREN="$(curl -XGET -s \
            -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
            -H "isAdminMode: true" \
            "${SUMOLOGIC_BASE_URL}"v2/content/folders/"${INTEGRATIONS_FOLDER_ID}" | \
            jq '.children[]')"
  readonly INTEGRATIONS_FOLDER_CHILDREN

  K8S_FOLDER_ID="$( echo "${INTEGRATIONS_FOLDER_CHILDREN}" | \
            jq -r "select(.name == \"${K8S_FOLDER_NAME}\") | .id" )"
}

load_dashboards_folder_id

if [[ -z "${K8S_FOLDER_ID}" ]]; then
  APP_INSTALL_JOB_RESPONSE="$(curl -XPOST -s \
         -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
         -H "isAdminMode: true" \
         -H "Content-Type: application/json" \
         -d "{\"name\":\"${K8S_FOLDER_NAME}\",\"destinationFolderId\":\"${INTEGRATIONS_FOLDER_ID}\",\"description\":\"Kubernetes dashboards provided by Sumo Logic.\"}" \
         "${SUMOLOGIC_BASE_URL}"v1/apps/"${K8S_APP_UUID}"/install )"
  readonly APP_INSTALL_JOB_RESPONSE

  APP_INSTALL_JOB_ID="$(echo "${APP_INSTALL_JOB_RESPONSE}" | jq '.id' | tr -d '"' )"
  readonly APP_INSTALL_JOB_ID

  APP_INSTALL_JOB_STATUS="InProgress"
  while [ "${APP_INSTALL_JOB_STATUS}" = "InProgress" ]; do
    APP_INSTALL_JOB_STATUS="$(curl -XGET -s \
          -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
          "${SUMOLOGIC_BASE_URL}"v1/apps/install/"${APP_INSTALL_JOB_ID}"/status | jq '.status' | tr -d '"' )"

    sleep 1
  done

  if [ "${APP_INSTALL_JOB_STATUS}" != "Success" ]; then
    ERROR_MSG="$(curl -XGET -s \
          -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
          "${SUMOLOGIC_BASE_URL}"v1/apps/install/"${APP_INSTALL_JOB_ID}"/status )"
    echo "${ERROR_MSG}"

    echo "Installation of the K8s Dashboards failed."
    echo "You can still install them manually:"
    echo "https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app"
    exit 2
  else
    load_dashboards_folder_id

    ORG_ID="$(curl -XGET -s \
            -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
            "${SUMOLOGIC_BASE_URL}"v1/account/contract | jq '.orgId' | tr -d '"' )"
    readonly ORG_ID

    PERMS_ERRORS=$( curl -XPUT -s \
      -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
      -H "isAdminMode: true" \
      -H "Content-Type: application/json" \
      -d "{\"contentPermissionAssignments\": [{\"permissionName\": \"View\",\"sourceType\": \"org\",\"sourceId\": \"${ORG_ID}\",\"contentId\": \"${K8S_FOLDER_ID}\"}],\"notifyRecipients\":false,\"notificationMessage\":\"\"}" \
      "${SUMOLOGIC_BASE_URL}"v2/content/"${K8S_FOLDER_ID}"/permissions/add | jq '.errors' )
    readonly PERMS_ERRORS

    if [ "${PERMS_ERRORS}" != "null" ]; then
      echo "Setting permissions for the installed content failed."
      echo "${PERMS_ERRORS}"
    fi

    echo "Installation of the K8s Dashboards succeeded."
  fi
else
  echo "The K8s Dashboards have been already installed."
  echo "You can (re)install them manually with:"
  echo "https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app"
fi
