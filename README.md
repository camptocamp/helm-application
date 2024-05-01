# [Kubernetes](https://kubernetes.io/) [HELM chart](https://helm.sh/) for a simple custom application

With this chart you can easily deploy a simple custom application on Kubernetes, with only configuration.

This will create a Deployment, a Service, a Pod Disruption Budget, optionally an Ingress, optionally a Service Account,
optionally a Pod Monitor (for Prometheus).

[See as example](./tests/values.yaml).

## Goals

The goals of this chart is double, it's to be able to deploy all the needed Kubernetes object to deploy a simple Pod,
and to be able one values file for the application, and one for the environment specific like integration
and production.

## Schema documentation

Documentation based on the schema defined in [values.md](./values.md).

## Contributing

Install the pre-commit hooks:

```bash
pip install pre-commit
pre-commit install --allow-missing-config
```

## Helpers present in this Chart

### `application.serviceAccountName`

Create the name of the service account to use.

Parameters:

- `root`: the root object, should be `$`.

Used values:

- [`serviceAccount`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/serviceAccount) from the values root (`$.Values`).

### `application.podConfig`

Create the pod configuration.

Parameters:

- `root`: the root object, should be `$`.
- `service`: the service object.
- `affinitySelector`: the affinity selector (optional).

Used values:

- [`image`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/globalImage) from the global values (`$.Values.global`).
- [`podSecurityContext`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/podSecurityContext) from the values root (`$.Values`).
- [`nodeSelector`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/nodeSelector) from the service object.
- [`affinity`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/affinity) from the service object.
- [`tolerations`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/tolerations) from the values root (`$.Values`).

Used Functions:

- `application.serviceAccountName`

### `application.containerConfig`

Create the container configuration.

Parameters:

- `root`: the root object, should be `$`.
- `container`: the container definition.

Used values:

- [`securityContext`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/securityContext) from the values root (`$.Values`).
- [`image`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/image) from the container object.
- [`image`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/globalImage) from the global values (`$.Values.global`).
- [`env`](https://github.com/camptocamp/helm-common/blob/master/values.md#definitions/env) from the container object.
- [`configMapNameOverride`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/configMapNameOverride) from the global values (`$.Values.global`).
- [`resources`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/resources) from the container object.

Used functions:

- `common.oneEnv`

### `application.podMetadata`

Create the metadata for the Pod.

Parameters:

- `service`: the service object.

Used values:

- [`podLabels`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/podLabels) from the service object.
- [`podAnnotations`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/podAnnotations) from the service object.

Used functions:

- `common.selectorLabels`

### `application.oneEnv`

Create one environment variable.

Parameters:

- `root`: the root object, should be `$`.
- `name`: the name of the environment variable.
- `value`: the definition of the [environment variable](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/env).
- [`configMapNameOverride`](https://github.com/camptocamp/helm-custom-pod/blob/master/values.md#definitions/configMapNameOverride): the name override of the ConfigMap to use.

Used functions:

- `common.fullname`

### Environment variables

In the container config you should define an `env` and `configMapNameOverride` dictionaries with, for the env:

The hey represent the environment variable name, and the value is a dictionary with a `type` key.

It the type is `value` (default) you can specify the value of the environment variable in `value`, example:

```yaml
env:
  VAR:
    type: value # default
    value: toto
```

If the type is `none` the environment variable will be ignored, example:

```yaml
env:
  VAR:
    type: none
```

If the type is `configMap` or `secret` you should have an `name` with the `ConfigMap` or `Secret` name,
and a `key` to know with key you want to get, example:

```yaml
env:
  VAR:
    type: configMap # or secret
    name: configmap-name
    key: key-in-configmap
```

We can also easily linked the internal `ConfigMap` or `Secret` with the `self[-metadata]` name, example:

```yaml
env:
  SELF_CONFIGMAP:
    type: configMap
    name: self
    key: <key>
  SELF_SECRET:
    type: secret
    name: self
    key: <key>
  SELF_METADATA:
    type: configMap
    name: self-metadata
    key: CHART_NAME # or anythings else
```

We also have an attribute `order` to be able to use the `$(env)` syntax, example:

```yaml
env:
  AA_VAR:
    value: aa$(ZZ_VAR)aa
    order: 1
  ZZ_VAR:
    value: zz
```

Currently we put at first the `order` <= `0` and at last the `order` > `0`, default is `0` (first).

## Image name

In the container config you should define the image like this:

```yaml
image:
  repository: camptocamp/mapserver
  tag: latest
  sha:
  pullPolicy: IfNotPresent
```

The sha will be taken in priority of the tag

## Pod affinity

In the `podConfig` you can have an `affinitySelector` to be able to configure a `podAntiAffinity`.

Example:

```
application.podConfig" ( dict
  "root" .
  "service" .Values
  "affinitySelector" (dict
    "app.kubernetes.io/instance" .Release.Name
    "app.kubernetes.io/name" ( include "common.name" . )
    "app.kubernetes.io/component" "<servicename>"
  )
)
```
