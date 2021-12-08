# [Kubernetes](https://kubernetes.io/) [HELM chart](https://helm.sh/) for application hosted by [Apache httpd](https://httpd.apache.org/)

The default config is for [MapServer](mapserver.org/) with the image
[docker-mapserver](https://github.com/camptocamp/docker-mapserver)

With:

- One config init container, the Mapfiles should de in `/etc/mapserver/`
- One [Apache Exporter for Prometheus](https://github.com/Lusitaniae/apache_exporter) container
- The [MapServer](https://github.com/camptocamp/docker-mapserver) container

Can be include in an other chart for `qgisserver` with e.g.:

`Chart.yaml`:

```
name: geomapfish
version: 1.0.0
apiVersion: v2
dependencies:
  - name: mapserver
    repository: file:///src/helm-mapserver/
    version: 1.0.0
    alias: qgisserver
    condition: qgisserver.enabled
```

`values.yaml`:

```
qgisserver:
  enabled: true
  replicaCount: 2
  image:
    repository: camptocamp/qgis-server
    tag: 3.20
  env: {}
  resources: {}
  readinessProbe:
    httpGet:
      path: /?SERVICE=WMS&REQUEST=GetCapabilities
      port: http
    initialDelaySeconds: 5
    timeoutSeconds: 300
  config:
    enabled: true
    image:
      repository: camptocamp/my-config-image
      tag: latest
    env: {}
    resources: {}
    folder: /etc/qgisserver
```
