# [Kubernetes](https://kubernetes.io/) [HELM chart](https://helm.sh/) for a simple application

With this chart you can easily deploy a simple application on Kubernetes, with only configuration.

This will create a Deployment, a Service, a Pod Disruption Budget, optionally an Ingress, optionally a Service Account,
optionally a Pod Monitor (for Prometheus).

[See as example](./tests/values.yaml).

## Goals

The goals of this chart is double, it's to be able to deploy all the needed Kubernetes object to deploy a simple Pod,
and to be able one values file for the application, and one for the environment specific like integration
and production.

## Documentation

Documentation based on the schema defined in [values.md](./values.md).
The documentation is on the [Wiki](https://github.com/camptocamp/helm-application/wiki).

## Installation

```bash
helm repo add application https://camptocamp.github.io/helm-application/
helm install my-release application/application --values=my-values.yaml
```

## Contributing

Install the pre-commit hooks:

```bash
pip install pre-commit
pre-commit install --allow-missing-config
```
