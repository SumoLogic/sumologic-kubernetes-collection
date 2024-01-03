# Linters

.PHONY: lint
lint: chart-lint docs-lint tests-lint

.PHONY: chart-lint
chart-lint: helm-lint yaml-lint shellcheck

.PHONY: docs-lint
docs-lint: markdown-lint markdown-links-lint check-configuration-keys

.PHONY: tests-lint
tests-lint: template-tests-lint integration-tests-lint

.PHONY: markdown-lint
markdown-lint:
	prettier --check "**/*.md"
	markdownlint --config .markdownlint.jsonc \
		docs \
		CHANGELOG.md

.PHONY: helm-lint
helm-lint: helm-version
# TODO: we should add back the --strict flag but because we have made the PodDisruptionBudget
# API version dependent on cluster capabilities and because helm lint does not accept
# an --api-versions flag like helm template does we cannot make this configurable.
#
# Perhaps we could at some point run this against a cluster with particular k8s version?
#
# https://github.com/SumoLogic/sumologic-kubernetes-collection/pull/1943
	helm lint \
		--set sumologic.accessId=X \
		--set sumologic.accessKey=X \
		deploy/helm/sumologic/
	helm lint --with-subcharts \
		--set sumologic.accessId=X \
		--set sumologic.accessKey=X \
		deploy/helm/sumologic/ || true

.PHONY: yaml-lint
yaml-lint:
	prettier --check "**/*.yaml" "**/*.yml"

.PHONY: shellcheck
shellcheck:
	./ci/shellcheck.sh

.PHONY: markdown-links-lint
markdown-links-lint:
	./ci/markdown_links_lint.sh

.PHONY: check-configuration-keys
check-configuration-keys:
	python -m unittest ./ci/check_configuration_keys_test.py
	./ci/check_configuration_keys.py --values deploy/helm/sumologic/values.yaml --readme deploy/helm/sumologic/README.md

.PHONY: check-dependencies
check-dependencies:
	@python ./ci/check_dependencies/main.py --quiet

.PHONY: template-tests-lint
template-tests-lint:
	make -C ./tests/helm golint

.PHONY: integration-tests-lint
integration-tests-lint:
	make -C ./tests/integration golint

# Formatters

.PHONY: format
format: markdown-format yaml-format

.PHONY: markdown-format
markdown-format:
	prettier -w "**/*.md"

.PHONY: yaml-format
yaml-format:
	prettier -w "**/*.yaml" "**/*.yml"

# Tests
.PHONY: test
test: test-templates

## Template tests
.PHONY: test-templates
test-templates:
	make helm-dependency-update
	make -C ./tests/helm test

### Regenerate golden files for template tests
### Be sure the output is what you expect before committing!
.PHONY: regenerate-goldenfiles
regenerate-goldenfiles:
	make -C ./tests/helm regenerate-goldenfiles
	make yaml-format

## Integration tests
.PHONY: test-integration
make test-integration:
	make -C ./tests/integration test


# Changelog management
## We use Towncrier (https://towncrier.readthedocs.io) for changelog management

## Usage: make add-changelog-entry
.PHONY: add-changelog-entry
add-changelog-entry:
	./ci/add-changelog-entry.sh

## Consume the files in .changelog and update CHANGELOG.md
## We also format it afterwards to make sure it's consistent with our style
## Usage: make update-changelog VERSION=x.x.x
.PHONY: update-changelog
update-changelog:
ifndef VERSION
	$(error Usage: make update-changelog VERSION=x.x.x)
endif
	towncrier build --yes --version $(VERSION)
	prettier -w CHANGELOG.md
	git add CHANGELOG.md

## Check if the branch relative to main adds a changelog entry
.PHONY: check-changelog
check-changelog:
	towncrier check

## Update OpenTelemetry Collector version
## Usage: make update-otc OTC_CURRENT_VERSION=0.73.0-sumo-1 OTC_NEW_VERSION=0.74.0-sumo-0
.PHONY: update-otc
update-otc:
	./ci/update-otc.sh ${OTC_CURRENT_VERSION} ${OTC_NEW_VERSION}

# Various utilities
.PHONY: push-helm-chart
push-helm-chart:
	./ci/push-helm-chart.sh

.PHONY: helm-version
helm-version:
	helm version

.PHONY: helm-dependency-update
helm-dependency-update: helm-version
	helm dependency update deploy/helm/sumologic

.PHONY: markdown-link-check
markdown-link-check:
	./ci/markdown_link_check.sh

.PHONE: tool-versions
tool-versions:
	kubectl version --client=true --short 2>/dev/null
	helm version
	jq --version
	yq --version
	markdown-link-check --version
	markdownlint --version
	prettier --version
	python -V
	towncrier --version
	shellcheck --version
	golangci-lint version
	go version
	kind version

# Vagrant commands
.PHONY: vup
vup:
	vagrant up

.PHONY: vssh
vssh:
	vagrant ssh -c 'cd /sumologic; exec "$$SHELL"'

.PHONY: vhalt
vhalt:
	vagrant halt

.PHONY: vdestroy
vdestroy:
	vagrant destroy -f
