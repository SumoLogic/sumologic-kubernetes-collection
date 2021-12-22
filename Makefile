lint: shellcheck markdownlint helm-lint yamllint markdown-links-lint markdown-table-formatter-check

shellcheck:
	./ci/shellcheck.sh

test:
	./ci/tests.sh

push-helm-chart:
	./ci/push-helm-chart.sh

markdownlint:
	markdownlint --config .markdownlint.jsonc \
		deploy/docs \
		CHANGELOG.md

.PHONY: helm-version
helm-version:
	helm version

.PHONY: helm-dependency-update
helm-dependency-update: helm-version
	helm dependency update deploy/helm/sumologic

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

yamllint:
	yamllint -c .yamllint.yaml\
		deploy/helm/sumologic/values.yaml \
		vagrant/values.yaml

markdown-links-lint:
	./ci/markdown_links_lint.sh

markdown-link-check:
	./ci/markdown_link_check.sh

markdown-table-formatter-check:
	./ci/markdown_table_formatter.sh --check

markdown-table-formatter-format:
	./ci/markdown_table_formatter.sh --format
