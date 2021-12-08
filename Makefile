HELM != helm3

gen-expected:
	${HELM} template --namespace=default --values=tests/values.yaml custom . > tests/expected.yaml
	sed -i 's/[[:blank:]]\+$$//g'  tests/expected.yaml
