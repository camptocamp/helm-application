# [Kubernetes](https://kubernetes.io/) [HELM chart](https://helm.sh/) for a simple custom application

With this chart you can easily deploy a simple custom application on Kubernetes, with only configuration.

This will create a Deployment, a Service, a Pod Disruption Budget, optionally an Ingress, optionally a Service Account,
optionally a Pod Monitor (for Prometheus).

[See as example](./tests/values.yaml).

## Schema documentation

Documentation based on the schema defined in [values.md](./values.md).

## Contributing

Install the pre-commit hooks:

```bash
pip install pre-commit
pre-commit install --allow-missing-config
```
