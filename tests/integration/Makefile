# For more images versions and SHAs go to https://github.com/kubernetes-sigs/kind/releases
# For default and supported images used in tests please see kind_images.json
K8S_NODE_IMAGE ?= $(shell jq '.default' kind_images.json)
CLUSTER_NAME ?= sumologic
KUBE_CONFIG ?= $(shell mktemp)

.PHONY: create-cluster
create-cluster:
	kind create cluster \
		--name $(CLUSTER_NAME) \
		--image $(K8S_NODE_IMAGE) \
		--kubeconfig $(KUBE_CONFIG)
	@echo "KUBECONFIG $(KUBE_CONFIG)"

.PHONY: delete-cluster
delete-cluster:
	kind delete cluster \
		--name $(CLUSTER_NAME)

.PHONY: test
test:
	go test -v -count 1 ./...

.PHONY: compile-test
compile-test:
	go test -c ./...
