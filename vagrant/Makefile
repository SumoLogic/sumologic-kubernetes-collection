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

# Collector section
## Collector upgrade
upgrade:
	${mkfile_path} \
		patch-context \
		remove-tmp \
		apply-namespaces \
		apply-receiver-mock \
		create-secrets \
		grafana-dashboards \
		helm-dependencies \
		helm-upgrade \
		apply-service-monitors

# Remove temporary charts
remove-tmp:
	rm -rf ${helm_path}/tmpcharts

apply-namespaces:
	kubectl apply -f ${k8s_path}/sumologic-namespace.yaml

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
		remove-service-monitors \
		remove-receiver-mock \
		remove-prometheus-crds \
		remove-namespaces

remove-namespaces:
	kubectl delete -f ${k8s_path}/sumologic-namespace.yaml --ignore-not-found=true

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
	kubectl -n demo-nginx-docker create configmap --from-file=${k8s_path}/application_metrics/nginx/docker/default.conf nginx-config || true
	kubectl -n demo-nginx-docker apply -f ${k8s_path}/application_metrics/nginx/docker/statefulset.yaml

application-metrics-nginx-docker-clean:
	kubectl delete ns demo-nginx-docker

## Nginx ingress controller
## rel: https://docs.nginx.com/nginx-ingress-controller/overview/

application-metrics-nginx-ingress-official-prometheus-run:
	kubectl create ns demo-nginx-ingress-official || true
	helm repo add nginx-stable https://helm.nginx.com/stable
	helm repo update
	helm upgrade demo-nginx-ingress-official nginx-stable/nginx-ingress \
		--install \
		--namespace demo-nginx-ingress-official \
		-f "${k8s_path}/application_metrics/nginx/ingress_official/values.prometheus.yaml"

application-metrics-nginx-ingress-official-telegraf-run:
	kubectl create ns demo-nginx-ingress-official || true
	helm repo add nginx-stable https://helm.nginx.com/stable
	helm repo update
	helm upgrade demo-nginx-ingress-official nginx-stable/nginx-ingress \
		--install \
		--namespace demo-nginx-ingress-official \
		-f "${k8s_path}/application_metrics/nginx/ingress_official/values.telegraf.yaml"

application-metrics-nginx-ingress-official-docker-clean:
	helm delete -n demo-nginx-ingress-official demo-nginx-ingress-official
	kubectl delete ns demo-nginx-ingress-official

application-metrics-nginx-ingress-k8s-telegraf-run:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo add stable https://kubernetes-charts.storage.googleapis.com/
	helm repo update
	helm upgrade demo-nginx-ingress-k8s ingress-nginx/ingress-nginx \
		--install \
		--create-namespace \
		--namespace demo-nginx-ingress-k8s \
		-f "${k8s_path}/application_metrics/nginx/ingress_k8s/values.telegraf.yaml"

application-metrics-nginx-ingress-k8s-telegraf-clean:
	helm delete -n demo-nginx-ingress-k8s demo-nginx-ingress-k8s
	kubectl delete ns demo-nginx-ingress-k8s

## Docker based redis
application-metrics-redis-docker-run:
	kubectl create ns demo-redis-docker || true
	kubectl -n demo-redis-docker apply -f ${k8s_path}/application_metrics/redis/docker/statefulset.yaml

application-metrics-redis-docker-clean:
	kubectl delete ns demo-redis-docker

application-metrics-demo-redis-bitnami-telegraf-run:
	kubectl create ns demo-redis-bitnami || true
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade demo-redis-bitnami bitnami/redis \
		--install \
		--namespace demo-redis-bitnami \
		-f "${k8s_path}/application_metrics/redis/bitnami/values.telegraf.yaml"

application-metrics-demo-redis-bitnami-prometheus-run:
	kubectl create ns demo-redis-bitnami || true
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade demo-redis-bitnami bitnami/redis \
		--install \
		--namespace demo-redis-bitnami \
		-f "${k8s_path}/application_metrics/redis/bitnami/values.prometheus.yaml"

application-metrics-nginx-ingress-official-docker-clean:
	helm delete -n demo-nginx-ingress-official demo-nginx-ingress-official
	kubectl delete ns demo-redis-bitnami

application-metrics-jolokia-docker-build:
	docker build /sumologic/vagrant/k8s/application_metrics/jmx/jolokia/docker/ -t localhost:32000/jolokia/docker
	docker push localhost:32000/jolokia/docker

application-metrics-jolokia-docker-run:
	kubectl create ns demo-jolokia-docker || true
	kubectl -n demo-jolokia-docker apply -f ${k8s_path}/application_metrics/jmx/jolokia/docker/statefulset.yaml

application-metrics-jolokia-docker-clean:
	kubectl delete ns demo-jolokia-docker

application-metrics-jmxexporter-docker-build:
	docker build /sumologic/vagrant/k8s/application_metrics/jmx/jmxexporter/docker/ -t localhost:32000/jmxexporter/docker
	docker push localhost:32000/jmxexporter/docker

application-metrics-jmxexporter-docker-run:
	kubectl create ns demo-jmxexporter-docker || true
	kubectl -n demo-jmxexporter-docker create configmap --from-file=${k8s_path}/application_metrics/jmx/jmxexporter/docker/config.yaml jmxexporter-config || true
	kubectl -n demo-jmxexporter-docker apply -f ${k8s_path}/application_metrics/jmx/jmxexporter/docker/statefulset.yaml

application-metrics-jmxexporter-docker-clean:
	kubectl delete ns demo-jmxexporter-docker

application-metrics-postgres-bitnami-telegraf-run:
	kubectl create ns demo-postgres-bitnami || true
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade demo-postgres-bitnami bitnami/postgresql \
		--install \
		--namespace demo-postgres-bitnami \
		-f "${k8s_path}/application_metrics/postgres/bitnami/values.telegraf.yaml"

application-metrics-postgres-bitnami-clean:
	kubectl delete ns demo-postgres-bitnami

application-metrics-kafka-strimzi-run:
	helm repo add strimzi https://strimzi.io/charts/
	helm upgrade kafka strimzi/strimzi-kafka-operator \
		--install \
		--create-namespace \
		--namespace demo-kafka-strimzi
	kubectl apply -f "${k8s_path}/application_metrics/kafka/strimzi/kafka-cluster.yaml"
	helm upgrade kafka-lag-exporter \
		https://github.com/lightbend/kafka-lag-exporter/releases/download/v0.6.3/kafka-lag-exporter-0.6.3.tgz \
		--namespace demo-kafka-strimzi \
		--set watchers.strimzi=true \
		--install

application-metrics-kafka-strimzi-clean:
	kubectl delete ns demo-kafka-strimzi
