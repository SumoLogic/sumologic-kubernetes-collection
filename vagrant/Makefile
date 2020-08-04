#!/usr/bin/make -f

# mkfile_path is absolute path of this file
# The intention is to be able to run this file from any location
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
# root_dir is a root directory of the project (github repo)
root_dir := $(dir $(abspath $(mkfile_path)/..))
helm_path = ${root_dir}deploy/helm/sumologic
k8s_path = ${root_dir}vagrant/k8s

# Collector configuration
cluster = microk8s
endpoint = http://receiver-mock.receiver-mock:3000/terraform/api/
access_id = dummy
access_key = dummy
name = collection
namespace = sumologic

# Collector section
## Collector upgrade
upgrade:
	${mkfile_path} \
		remove-tmp \
		apply-namespace \
		apply-receiver-mock \
		helm-dependencies \
		helm-upgrade \
		apply-service-monitors

# Remove temporary charts
remove-tmp:
	rm -rf ${helm_path}/tmpcharts

apply-namespace:
	kubectl apply -f ${k8s_path}/sumologic.yaml

apply-receiver-mock:
	kubectl apply -f ${k8s_path}/receiver-mock.yaml

helm-dependencies:
	helm dependency update "${helm_path}"

helm-upgrade:
	helm upgrade "${name}" "${helm_path}" \
		--namespace "${namespace}" \
		--install \
		--set sumologic.accessId="${access_id}" \
		--set sumologic.accessKey="${access_key}" \
		--set prometheus-operator.prometheus.prometheusSpec.externalLabels.cluster="${cluster}" \
		--set sumologic.clusterName="${cluster}" \
		--set sumologic.endpoint="${endpoint}"

apply-service-monitors:
	kubectl apply -f ${k8s_path}/service-monitors.yaml

## Collector removing
clean:
	${mkfile_path} \
		remove-collector \
		remove-service-monitors remove-receiver-mock remove-prometheus-crds remove-namespace

remove-namespace:
	kubectl delete -f ${k8s_path}/sumologic.yaml --ignore-not-found=true

remove-prometheus-crds:
	kubectl delete customresourcedefinitions.apiextensions.k8s.io  --ignore-not-found=true \
		{alertmanagers,podmonitors,prometheuses,prometheusrules,servicemonitors,thanosrulers}.monitoring.coreos.com

remove-receiver-mock:
	kubectl delete -f ${k8s_path}/receiver-mock.yaml --ignore-not-found=true

remove-collector:
	helm delete -n "${namespace}" "${name}"

remove-service-monitors:
	kubectl delete -f ${k8s_path}/service-monitors.yaml --ignore-not-found=true
