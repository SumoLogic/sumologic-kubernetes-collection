shellcheck:
	./ci/shellcheck.sh

test:
	./ci/tests.sh

build:
	./ci/build.sh

push:
	./ci/push.sh

markdownlint: mdl

mdl:
	mdl --style .markdownlint/style.rb deploy/docs

yamllint:
	yamllint -c .yamllint.yaml\
		deploy/helm/sumologic/values.yaml \
		vagrant/values.yaml
