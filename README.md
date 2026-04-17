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

## Horizontal Pod Autoscaler (HPA)

The `services.<name>.hpa` block renders an `autoscaling/v2` `HorizontalPodAutoscaler` targeting the Deployment created for that service.

The chart currently maps these HPA spec fields directly:

- `hpa.minReplicas` -> `spec.minReplicas`
- `hpa.maxReplicas` -> `spec.maxReplicas`
- `hpa.metrics` -> `spec.metrics`
- `hpa.behavior` -> `spec.behavior`

That means both `scaleUp` and `scaleDown` can be configured through `hpa.behavior`.

Example:

```yaml
services:
  example:
    containers:
      main:
        image:
          repository: camptocamp/image
          tag: latest
    hpa:
      minReplicas: 2
      maxReplicas: 5
      metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 50
      behavior:
        scaleUp:
          policies:
            - type: Percent
              value: 100
              periodSeconds: 60
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 10
              periodSeconds: 60
```

## Contributing

Install the pre-commit hooks:

```bash
pip install pre-commit
pre-commit install --allow-missing-config
```
