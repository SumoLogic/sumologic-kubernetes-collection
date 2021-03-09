shellcheck:
	./ci/shellcheck.sh

test:
	./ci/tests.sh

push-helm-chart:
	./ci/push-helm-chart.sh

markdownlint: mdl

mdl:
	mdl --style .markdownlint/style.rb deploy/docs

helm-dependency-update:
	helm dependency update deploy/helm/sumologic

helm-lint:
	helm lint --strict \
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
