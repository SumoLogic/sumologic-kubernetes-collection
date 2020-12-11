shellcheck:
	./ci/shellcheck.sh

test:
	./ci/tests.sh

push-helm-chart:
	./ci/push-helm-chart.sh

markdownlint: mdl

mdl:
	mdl --style .markdownlint/style.rb deploy/docs

yamllint:
	yamllint -c .yamllint.yaml\
		deploy/helm/sumologic/values.yaml \
		vagrant/values.yaml
