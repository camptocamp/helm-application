HELM != helm

gen-expected:
	${HELM} template --namespace=default --values=tests/values.yaml custom . > tests/expected.yaml || \
		${HELM}	template --debug --namespace=default --values=tests/values.yaml custom .
	sed -i 's/[[:blank:]]\+$$//g'  tests/expected.yaml
