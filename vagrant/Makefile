#!/usr/bin/make -f

# mkfile_path is absolute path of this file
# The intention is to be able to run this file from any location
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
# root_dir is a root directory of the project (github repo)
root_dir := $(dir $(abspath $(mkfile_path)/..))
helm_path = ${root_dir}deploy/helm/sumologic
k8s_path = ${root_dir}vagrant/k8s
dashboards_path = ${root_dir}vagrant/dashboards
local_values_file = ${root_dir}vagrant/values.local.yaml
vagrant_scripts_dir = ${root_dir}vagrant/scripts

# Collector configuration
name = collection
namespace = sumologic

test:
	$(MAKE) -C ${root_dir} test

generate-local-config:
	${vagrant_scripts_dir}/generate-local-config.sh

# Collector section
## Collector upgrade
upgrade:
	${mkfile_path} \
		patch-context \
		remove-tmp \
		apply-namespace \
		grafana-dashboards \
		helm-dependencies \
		helm-upgrade \
		apply-service-monitors

# Remove temporary charts
remove-tmp:
	rm -rf ${helm_path}/tmpcharts

apply-namespace:
	kubectl apply -f ${k8s_path}/sumologic.yaml

helm-dependencies:
	helm dependency update "${helm_path}"

helm-upgrade:
	$(eval local_values_param := $(shell [ -f ${local_values_file} ] && echo "-f ${local_values_file}" || echo ""))
	helm upgrade "${name}" "${helm_path}" \
		--namespace "${namespace}" \
		--install \
		-f "${root_dir}vagrant/values.yaml" ${local_values_param}

apply-service-monitors:
	kubectl apply -f ${k8s_path}/service-monitors.yaml

apply-avalanche:
	kubectl apply -f ${k8s_path}/avalanche.yaml

# This applies prometheus remote write rule to forward all avalanche metrics to receiver-mock
# Since this removes the generated values.local.yaml after it's applied subsequent 'make helm-upgrade'
# will revert this change.
apply-avalanche-remote-write: _apply-avalanche-remote-write-to-local-values helm-upgrade clean-local-values-yaml

clean-local-values-yaml:
	rm ${local_values_file}

_apply-avalanche-remote-write-to-local-values: generate-local-config
	yq -i '. *= load("${vagrant_scripts_dir}/yq/avalanche-remote-write.yaml")' ${local_values_file}

# Make sure avalanche remote write rule is applied in prometheus by running
# 'apply-avalanche-remote-write' target and verifying it in prometheus itself:
# kubectl exec -it prometheus-collection-prometheus-oper-prometheus-0 --container prometheus -- cat /etc/prometheus/config_out/prometheus.env.yaml
run-perf-test:
	TEST_DURATION=300 TEST_WARMUP_DURATION=30 ./scripts/perf-test.sh

## Collector removing
clean:
	${mkfile_path} \
		remove-collector \
		remove-service-monitors remove-receiver-mock remove-prometheus-crds remove-namespace

remove-avalanche:
	kubectl delete -f ${k8s_path}/avalanche.yaml --ignore-not-found=true

remove-namespace:
	kubectl delete -f ${k8s_path}/sumologic.yaml --ignore-not-found=true

remove-prometheus-crds:
	for crd in alertmanagers alertmanagerconfigs podmonitors probes prometheuses prometheusrules servicemonitors thanosrulers; do \
		kubectl delete customresourcedefinitions.apiextensions.k8s.io --ignore-not-found=true $$crd.monitoring.coreos.com; \
	done

remove-collector:
	helm delete -n "${namespace}" "${name}"

remove-service-monitors:
	kubectl delete -f ${k8s_path}/service-monitors.yaml --ignore-not-found=true

## k8s commands
expose-prometheus:
	kubectl port-forward -n "${namespace}" service/collection-kube-prometheus-prometheus --address=0.0.0.0 9090

expose-grafana:
	echo "Grafana credentials\n  login:    admin\n  password: prom-operator"
	kubectl port-forward -n "${namespace}" service/collection-grafana --address=0.0.0.0 8080:80

# Load grafana dashboards as configmaps
grafana-dashboards:
	kubectl delete configmap -n "${namespace}" sumologic-dashboards || true
	kubectl create configmap -n "${namespace}" sumologic-dashboards --from-file="${dashboards_path}"

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
application-metrics-jmxexporter-docker-run:
	kubectl create ns demo-jmxexporter-docker || true
	kubectl -n demo-jmxexporter-docker apply -f ${k8s_path}/application_metrics/jmx/jmxexporter/docker/configmap.yaml
	kubectl -n demo-jmxexporter-docker apply -f ${k8s_path}/application_metrics/jmx/jmxexporter/docker/statefulset.yaml

application-metrics-jmxexporter-docker-clean:
	kubectl delete ns demo-jmxexporter-docker

## Jolokia based JMX
### Jolokia as javagent
application-metrics-jolokia-docker-run:
	kubectl create ns demo-jolokia-docker || true
	kubectl -n demo-jolokia-docker apply -f ${k8s_path}/application_metrics/jmx/jolokia/docker/statefulset.yaml

application-metrics-jolokia-docker-clean:
	kubectl delete ns demo-jolokia-docker

### Jolokia as standalone application

application-metrics-jolokia-agent-run:
	kubectl create ns demo-jolokia-agent || true
	kubectl -n demo-jolokia-agent apply -f ${k8s_path}/application_metrics/jmx/jolokia/agent/statefulset.yaml

application-metrics-jolokia-agent-clean:
	kubectl delete ns demo-jolokia-agent

test-receiver-mock-logs:
	kubectl logs $(shell kubectl get pod -l app=receiver-mock -o jsonpath='{.items[0].metadata.name}'  -n receiver-mock) -n receiver-mock

test-receiver-mock-metrics:
	kubectl exec $(shell kubectl get pod -l app=receiver-mock -o jsonpath="{.items[0].metadata.name}"  -n receiver-mock) -it -n receiver-mock -- curl http://localhost:3000/metrics

shellcheck:
	$(MAKE) -C ${root_dir} shellcheck

markdownlint:
	$(MAKE) -C ${root_dir} markdownlint

yamllint:
	$(MAKE) -C ${root_dir} yamllint

markdown-links-lint:
	$(MAKE) -C ${root_dir} markdown-links-lint

## Testing tools
apply-logs-keeper:
	kubectl delete configmap -n logs-keeper logs-keeper || true
	kubectl apply -n logs-keeper -f ${k8s_path}/logs-keeper.yaml
	kubectl create configmap -n logs-keeper logs-keeper --from-file="${root_dir}vagrant/logs-keeper/logs-keeper.py"

remove-logs-keeper:
	kubectl delete ns logs-keeper --ignore-not-found=true

apply-logs-generator:
	kubectl apply -f ${k8s_path}/logs-generator.yaml

remove-logs-generator:
	kubectl delete -f ${k8s_path}/logs-generator.yaml --ignore-not-found=true

## Prometheus adapter can be used to expose custom metrics for HPA
## This is just an example deployment
## See https://github.com/kubernetes-sigs/prometheus-adapter for more informations
apply-prometheus-adapter:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade adapter \
		--namespace prometheus-adapter \
		--create-namespace \
		--install prometheus-community/prometheus-adapter \
		-f "${k8s_path}/prometheus-adapter.yaml"

## Istio
istio-clone:
	rm -rf /home/vagrant/istio
	if [ ! -d "/home/vagrant/istio" ] ; then git clone https://github.com/istio/istio.git /home/vagrant/istio; fi

istio-certs:
	# https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/#plug-in-certificates-and-key-into-the-cluster
	mkdir -p /home/vagrant/istio/certs
	cd /home/vagrant/istio/certs && \
		make -f ../tools/certs/Makefile.selfsigned.mk root-ca && \
		make -f ../tools/certs/Makefile.selfsigned.mk microk8s-cluster-cacerts && \
		(kubectl create namespace istio-system || true) && \
		kubectl delete secret cacerts -n istio-system --ignore-not-found=true && \
		kubectl create secret generic cacerts -n istio-system \
		--from-file=microk8s-cluster/ca-cert.pem \
		--from-file=microk8s-cluster/ca-key.pem \
		--from-file=microk8s-cluster/root-cert.pem \
		--from-file=microk8s-cluster/cert-chain.pem

istio-enable:
	microk8s.enable istio

istio-patch: istio-patch-receiver-mock istio-patch-sumologic istio-patch-service-monitors

istio-patch-receiver-mock:
	kubectl label namespace receiver-mock istio-injection=enabled --overwrite
	kubectl apply -n receiver-mock -f ${k8s_path}/istio-peer-authentication.yaml
	kubectl apply -f ${k8s_path}/istio-receiver-mock.yaml

istio-patch-sumologic:
	kubectl label namespace sumologic istio-injection=enabled --overwrite
	kubectl apply -n sumologic -f ${k8s_path}/istio-peer-authentication.yaml

istio-patch-service-monitors:
	kubectl apply -f ${k8s_path}/istio-service-monitors.yaml

istio-disable:
	microk8s.disable istio

restart-pods:
	kubectl -n sumologic delete pod --all --force --grace-period=0

install-argocd-binary:
	curl -LO https://github.com/argoproj/argo-cd/releases/download/v2.9.3/argocd-linux-amd64
	chmod +x argocd-linux-amd64
	sudo mv argocd-linux-amd64 /usr/local/bin/argocd

install-argocd:
	${mkfile_path} \
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
	argocd admin initial-password -n argocd

expose-argocd:
	kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
