#!/usr/bin/make -f

# mkfile_path is absolute path of this file
# The intention is to be able to run this file from any location
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
# root_dir is a root directory of the project (github repo)
root_dir := $(dir $(abspath $(mkfile_path)/..))
helm_path = ${root_dir}deploy/helm/sumologic
k8s_path = ${root_dir}vagrant/k8s
dashboards_path = ${root_dir}vagrant/dashboards

# Collector configuration
name = collection
namespace = sumologic

build:
	cd ${root_dir} && ${root_dir}ci/build.sh

# Collector section
## Collector upgrade
upgrade:
	${mkfile_path} \
		patch-context \
		remove-tmp \
		apply-namespace \
		apply-receiver-mock \
		create-secrets \
		grafana-dashboards \
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
		-f "${root_dir}vagrant/values.yaml"

apply-service-monitors:
	kubectl apply -f ${k8s_path}/service-monitors.yaml

apply-avalanche:
	kubectl apply -f ${k8s_path}/avalanche.yaml

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

## k8s commands
expose-prometheus:
	kubectl port-forward -n "${namespace}" service/collection-prometheus-oper-prometheus --address=0.0.0.0 9090

expose-grafana:
	echo "Grafana credentials\n  login:    admin\n  password: prom-operator"
	kubectl port-forward -n "${namespace}" service/collection-grafana --address=0.0.0.0 8080:80

# Load grafana dashboards as configmaps
grafana-dashboards:
	kubectl delete configmap -n "${namespace}" sumologic-dashboards || true
	kubectl create configmap -n "${namespace}" sumologic-dashboards --from-file="${dashboards_path}"

# Create secrets with microk8s certs
create-secrets:
	kubectl delete secret -n "${namespace}" microk8s-certs || true
	kubectl create secret -n "${namespace}" generic microk8s-certs \
		--from-file=/var/snap/microk8s/current/certs/server.key \
		--from-file=/var/snap/microk8s/current/certs/server.crt \
		--from-file=/var/snap/microk8s/current/certs/ca.crt

# patch context to use sumologic namespace as default
patch-context:
	kubectl config set-context --current --namespace "${namespace}"

# Application metrics demo
## Docker based nginx
application-metrics-nginx-docker-run:
	kubectl create ns demo-nginx-docker || true
	kubectl -n demo-nginx-docker apply -f ${k8s_path}/application_metrics/nginx/docker/configmap.yaml
	kubectl -n demo-nginx-docker apply -f ${k8s_path}/application_metrics/nginx/docker/statefulset.yaml

application-metrics-nginx-docker-clean:
	kubectl delete ns demo-nginx-docker

## Nginx ingress controller
## rel: https://docs.nginx.com/nginx-ingress-controller/overview/

application-metrics-nginx-ingress-official-prometheus-run:
	helm repo add nginx-stable https://helm.nginx.com/stable
	helm repo update
	helm upgrade demo-nginx-ingress-official nginx-stable/nginx-ingress \
		--install \
		--namespace demo-nginx-ingress-official \
		--create-namespace \
		-f "${k8s_path}/application_metrics/nginx/ingress_official/values.prometheus.yaml"

application-metrics-nginx-ingress-official-telegraf-run:
	helm repo add nginx-stable https://helm.nginx.com/stable
	helm repo update
	helm upgrade demo-nginx-ingress-official nginx-stable/nginx-ingress \
		--install \
		--namespace demo-nginx-ingress-official \
		--create-namespace \
		-f "${k8s_path}/application_metrics/nginx/ingress_official/values.telegraf.yaml"

application-metrics-nginx-ingress-official-clean:
	helm delete -n demo-nginx-ingress-official demo-nginx-ingress-official
	kubectl delete ns demo-nginx-ingress-official

## Docker based redis
application-metrics-redis-docker-run:
	kubectl create ns demo-redis-docker || true
	kubectl -n demo-redis-docker apply -f ${k8s_path}/application_metrics/redis/docker/statefulset.yaml

application-metrics-redis-docker-clean:
	kubectl delete ns demo-redis-docker

## Bitnami based redis
application-metrics-redis-bitnami-telegraf-run:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade demo-redis-bitnami bitnami/redis \
		--install \
		--namespace demo-redis-bitnami \
		--create-namespace \
		-f "${k8s_path}/application_metrics/redis/bitnami/values.telegraf.yaml"

application-metrics-redis-bitnami-prometheus-run:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade demo-redis-bitnami bitnami/redis \
		--install \
		--namespace demo-redis-bitnami \
		--create-namespace \
		-f "${k8s_path}/application_metrics/redis/bitnami/values.prometheus.yaml"

application-metrics-redis-bitnami-clean:
	helm delete -n demo-redis-bitnami demo-redis-bitnami
	kubectl delete ns demo-redis-bitnami

## JMXExporter based JMX
application-metrics-jmxexporter-docker-build:
	docker build /sumologic/vagrant/k8s/application_metrics/jmx/jmxexporter/docker/ -t localhost:32000/jmxexporter/docker
	docker push localhost:32000/jmxexporter/docker

application-metrics-jmxexporter-docker-run:
	kubectl create ns demo-jmxexporter-docker || true
	kubectl -n demo-jmxexporter-docker apply -f ${k8s_path}/application_metrics/jmx/jmxexporter/docker/configmap.yaml
	kubectl -n demo-jmxexporter-docker apply -f ${k8s_path}/application_metrics/jmx/jmxexporter/docker/statefulset.yaml

application-metrics-jmxexporter-docker-clean:
	kubectl delete ns demo-jmxexporter-docker
