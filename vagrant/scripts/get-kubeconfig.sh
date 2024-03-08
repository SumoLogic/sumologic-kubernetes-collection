#!/usr/bin/env bash
set -euo pipefail

# This script replaces kubeconfig with configuration for vagrant cluster

clean_up() {
	rm "${SSH_CONFIG_PATH}" || true
	rm "${CONFIG_PATH}" || true
	rmdir "${TEMP_DIR}" || true
	popd > /dev/null || true
}

err_report() {
    echo "Script error on line $1"
	clean_up
    exit 1
}
trap 'err_report $LINENO' ERR

readonly DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
readonly ROOT_DIR="${DIR}/../../"
readonly TEMP_DIR="$(mktemp -d)"
readonly SSH_CONFIG_PATH="${TEMP_DIR}/ssh-connect.conf"
readonly VAGRANT_IP="192.168.56.2"
readonly CONFIG_PATH="${TEMP_DIR}/config"
readonly KUBECONFIG_PATH=~/.kube/config

pushd "${ROOT_DIR}" > /dev/null
vagrant ssh-config > "${SSH_CONFIG_PATH}"
ssh -o StrictHostKeyChecking=no -F "${SSH_CONFIG_PATH}" default 'kubectl config view --raw' | \
	sed "s/127.0.0.1/${VAGRANT_IP}/g" > "${CONFIG_PATH}"

TODAY="$(date +%s)"
mv -v "${KUBECONFIG_PATH}" "${KUBECONFIG_PATH}.bkp.${TODAY}"
cp "${CONFIG_PATH}" "${KUBECONFIG_PATH}"

# Set default namespace to sumologic
kubectl config set-context --current --namespace sumologic

clean_up
