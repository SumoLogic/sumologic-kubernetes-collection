.PHONY: test
test:
	go test -timeout 30m -v

.PHONY: regenerate-goldenfiles
regenerate-goldenfiles:
	REGENERATE_GOLDENFILES=1 go test -run=^TestGoldenFiles$ || true

.PHONY: gomod-tidy
gomod-tidy:
	go mod tidy -compat=1.19

LINT=golangci-lint
GOLANGCI_LINT_VERSION ?= v1.51.0

.PHONY: install-golint
install-golangci-lint:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
	sh -s -- -b $(shell go env GOPATH)/bin $(GOLANGCI_LINT_VERSION)

.PHONY: golint
golint:
	$(LINT) run --verbose

.PHONY: gofmt
gofmt:
	gofmt -s -w .
