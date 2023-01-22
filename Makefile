# Linters

.PHONY: lint
lint: chart-lint docs-lint tests-lint

.PHONY: chart-lint
chart-lint: helm-lint yaml-lint shellcheck

.PHONY: docs-lint
docs-lint: markdown-lint markdown-links-lint markdown-table-formatter-check

.PHONY: tests-lint
tests-lint: template-tests-lint integration-tests-lint

.PHONY: markdown-lint
markdown-lint:
	markdownlint --config .markdownlint.jsonc \
		deploy/docs \
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
	yamllint -c .yamllint.yaml \
		deploy/helm/sumologic/values.yaml \
		vagrant/values.yaml

.PHONY: shellcheck
shellcheck:
	./ci/shellcheck.sh

.PHONY: markdown-links-lint
markdown-links-lint:
	./ci/markdown_links_lint.sh

.PHONY: markdown-table-formatter-check
markdown-table-formatter-check:
	./ci/markdown_table_formatter.sh --check

.PHONY: check-configuration-keys
check-configuration-keys:
	./ci/check_configuration_keys.py --values deploy/helm/sumologic/values.yaml --readme deploy/helm/sumologic/README.md

.PHONY: markdown-table-formatter-check
template-tests-lint:
	make -C ./tests/helm golint

.PHONY: integration-tests-lint
integration-tests-lint:
	make -C ./tests/helm golint

# Formatters

.PHONY: format
format: markdown-table-formatter-format

.PHONY: markdown-table-formatter-format
markdown-table-formatter-format:
	./ci/markdown_table_formatter.sh

# Tests
.PHONY: test
test: test-templates

## Template tests
.PHONY: test-templates
test-templates:
	make helm-dependency-update
	make -C ./tests/helm test

## Integration tests
.PHONY: test-integration
make test-integration:
	make -C ./tests/integration test


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
