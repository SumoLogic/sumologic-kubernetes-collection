#!/usr/bin/env bash

set -euo pipefail

# Create a docker image archive of all images used in test values files

IMAGE_ARCHIVE=${IMAGE_ARCHIVE:-images.tar}
MANIFESTS_TEMPFILE=${MANIFESTS_TEMPFILE:-/tmp/manifests.yaml}
IMAGES_TEMPFILE=${IMAGES_TEMPFILE:-/tmp/images.txt}
DUPLICATED_IMAGES_TEMPFILE="${IMAGES_TEMPFILE}.duplicated"

rm -f "${MANIFESTS_TEMPFILE}"

# Generate manifests for all values files and store them in the manifests tempfile
for values_file in values/*.yaml; do
    echo "Generating manifests for values file ${values_file}";
    helm template collection ../../deploy/helm/sumologic \
        -f "${values_file}" \
        --set-string "sumologic.accessId=accessId,sumologic.accessKey=accessKey" \
        >> "${MANIFESTS_TEMPFILE}";
done
echo

# Get the image names and deduplicate them
sed -n "s/^.*image: \([^:]*:.*\)$/\1/p" /tmp/manifests.yaml | tr -d \" >"${DUPLICATED_IMAGES_TEMPFILE}"
sed -n "s/^.*image: \(.*\)$/\1/p" yamls/*.yaml | tr -d \" >>"${DUPLICATED_IMAGES_TEMPFILE}"
sort "${DUPLICATED_IMAGES_TEMPFILE}" | uniq >"${IMAGES_TEMPFILE}"

# Create the archive
echo "Creating docker image archive containing the following images:"
echo
cat "${IMAGES_TEMPFILE}"
echo
echo "Pulling docker images:"
while read -r image
do
    docker pull -q "${image}"
done <"${IMAGES_TEMPFILE}"

echo "Saving archive"
xargs -x -n 50 docker save -o "${IMAGE_ARCHIVE}" <"${IMAGES_TEMPFILE}"
