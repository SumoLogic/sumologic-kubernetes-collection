#!/usr/bin/env bash

SRC_REPOSITORY=${1}
DESTINATION_NAMESPACE=${2}

if [[ "${SRC_REPOSITORY}" == "docker.io/bitnamilegacy/metrics-server" ]]; then
  echo "Syncing latest 5 tags for ${SRC_REPOSITORY} to avoid rate limits..."
  REPO_NAME=$(basename "${SRC_REPOSITORY}")

  # Check if destination is local to disable TLS verification
  DEST_TLS_VERIFY="true"
  if [[ "${DESTINATION_NAMESPACE}" == *"host.docker.internal"* || "${DESTINATION_NAMESPACE}" == *"localhost"* ]]; then
    DEST_TLS_VERIFY="false"
  fi

  # Fetch top 5 tags from Docker Hub API sorted by last_updated (descending)
  REPO_PATH=${SRC_REPOSITORY#docker.io/}
  API_URL="https://hub.docker.com/v2/repositories/${REPO_PATH}/tags/?page_size=5&ordering=last_updated"

  echo "Fetching tags from ${API_URL}..."
  TAGS=$(curl -s "${API_URL}" | python3 -c "import sys, json; print('\n'.join([t['name'] for t in json.load(sys.stdin)['results']]))")

  echo "Selected tags (latest uploaded):"
  echo "$TAGS"

  for TAG in $TAGS; do
    echo "Syncing ${TAG}..."
    docker run \
      -v ~/.docker/config.json:/tmp/auth.json \
      quay.io/skopeo/stable:v1.15.0 \
      copy \
      --all \
      --retry-times 5 \
      --src-no-creds \
      --dest-tls-verify=${DEST_TLS_VERIFY} \
      "docker://${SRC_REPOSITORY}:${TAG}" \
      "docker://${DESTINATION_NAMESPACE}/${REPO_NAME}:${TAG}"
  done
  exit 0
fi

docker run \
    -v ~/.docker/config.json:/tmp/auth.json \
    quay.io/skopeo/stable:v1.15.0 \
        sync \
            --all \
            --keep-going \
            --preserve-digests \
            --retry-times 5 \
            --src docker \
            --src-no-creds \
            --dest docker \
            "${SRC_REPOSITORY}" \
            "${DESTINATION_NAMESPACE}"
