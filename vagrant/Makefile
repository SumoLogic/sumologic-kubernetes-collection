#!/usr/bin/make -f

path = /sumologic/deploy/helm/sumologic
cluster = microk8s

provision:
	rm -rf ${path}/tmpcharts
	kubectl apply -f k8s/sumologic.yaml
	kubectl apply -f k8s/receiver-mock.yaml
	helm dependency update "${path}"
	helm upgrade collection "${path}" \
		--namespace sumologic \
		--install \
		--set sumologic.accessId="dummy" \
		--set sumologic.accessKey="dummy" \
    	--set prometheus-operator.prometheus.prometheusSpec.externalLabels.cluster="${cluster}" \
    	--set sumologic.clusterName="${cluster}" \
    	--set sumologic.endpoint="http://receiver-mock.receiver-mock:3000/terraform/api/"
	kubectl apply -f k8s/service-monitors.yaml
