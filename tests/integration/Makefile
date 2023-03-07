# For more images versions and SHAs go to https://github.com/kubernetes-sigs/kind/releases
# For default and supported images used in tests please see kind_images.json
KIND_NODE_IMAGE ?= $(shell jq '.default' kind_images.json)
CLUSTER_NAME ?= sumologic
IMAGE_ARCHIVE ?= images.tar
KUBE_CONFIG := $(shell mktemp)

.PHONY: create-cluster
create-cluster:
	kind create cluster \
		--config yamls/cluster.yaml \
		--name $(CLUSTER_NAME) \
		--image $(KIND_NODE_IMAGE) \
		--kubeconfig $(KUBE_CONFIG)

.PHONY: delete-cluster
delete-cluster:
	kind delete cluster \
		--name $(CLUSTER_NAME)

.PHONY: test
test:
	KIND_NODE_IMAGE=$(KIND_NODE_IMAGE) \
		go test -timeout 30m -v -count 1 -run=$(TEST_NAME) . -args $(TEST_ARGS)

.PHONY: create-image-archive
create-image-archive:
	IMAGE_ARCHIVE=$(IMAGE_ARCHIVE) bash create-image-archive.sh

.PHONY: gomod-tidy
gomod-tidy:
	go mod tidy -compat=1.18

LINT=golangci-lint
GOLANGCI_LINT_VERSION ?= v1.51.0

.PHONY: install-golint
install-golangci-lint:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
	sh -s -- -b $(shell go env GOPATH)/bin $(GOLANGCI_LINT_VERSION)

.PHONY: golint
golint:
	$(LINT) run --verbose
