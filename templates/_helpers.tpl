{{/*
Create the name of the service account to use
*/}}
{{- define "application.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- include "common.fullname" ( dict "root" . "service" .Values.serviceAccount ) }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "application.oneEnv" }}
{{- if eq ( default "value" .value.type ) "value" }}
- name: {{ .name | quote }}
  {{- dict "value" .value.value | toYaml | nindent 2 }}
{{- else if or (eq ( default "value" .value.type ) "configMap") (eq ( default "value" .value.type ) "secret") }}
- name: {{ .name | quote }}
  valueFrom:
    {{ .value.type }}KeyRef:
      {{ if and (hasKey .value "name" ) ( eq .value.name "self" ) -}}
      {{ if .value.type | eq "configMap" -}}
      name: {{ include "common.fullname" ( dict "root" .root "service" .root.Values.configMaps ) }}
      {{ else -}}
      name: {{ include "common.fullname" ( dict "root" .root "service" .root.Values.secrets ) }}
      {{ end -}}
      {{ else if and (hasKey .value "name" ) ( eq .value.name "self-metadata" ) -}}
      name: {{ include "common.fullname" ( dict "root" .root "service" .root.Values "serviceName" "metadata" ) }}
      {{ else -}}
      name: {{ default .value.name ( get .configMapNameOverride .value.name ) | quote }}
      {{ end -}}
      key: {{ .value.key | quote }}
{{- else }}
{{- if ne .value.type "none" }}
- name: {{ .name | quote }}
  valueFrom:
  {{- toYaml .value.valueFrom | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "application.podConfig" -}}
{{- if .root.Values.global.image.pullSecrets }}
imagePullSecrets:
{{- toYaml .root.Values.global.image.pullSecrets | nindent 2 }}
{{- else }}
{{- if .root.Values.dockerregistry -}}
imagePullSecrets:
  - name: {{ include "common.fullname" ( dict "root" .root "service" .root.Values "serviceName" "dockerregistry" ) }}
{{- end }}
{{- end }}
serviceAccountName: {{ include "application.serviceAccountName" ( .root ) }}
securityContext: {{- toYaml .root.Values.podSecurityContext | nindent 2 }}
{{- with .service.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or (and (hasKey .service "affinity") (.service.affinity)) .affinitySelector (hasKey .root.Values "affinity") -}}
affinity:
  {{- if and (hasKey .service "affinity") (.service.affinity) -}}
    {{ toYaml .service.affinity | nindent 2 }}
  {{- else if .affinitySelector }}
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        {{- range $key, $value := .affinitySelector }}
        - key: {{ $key }}
          operator: In
          values:
          - {{ $value }}
        {{- end }}
      topologyKey: "kubernetes.io/hostname"
  {{- else -}}
    {{ toYaml .root.Values.affinity | nindent 2 }}
  {{- end }}
{{- end }}
{{- with .root.Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "application.containerConfig" -}}
securityContext: {{- toYaml .root.Values.securityContext | nindent 2 }}
{{- if .container.image.sha }}
image: "{{ .container.image.repository }}@sha256:{{ .container.image.sha }}"
{{- else }}
image: "{{ .container.image.repository }}:{{ .container.image.tag }}"
{{- end }}
imagePullPolicy: {{ .root.Values.global.image.pullPolicy }}
{{- if not ( empty .container.env ) }}
env:
  {{- $configMapNameOverride := .root.Values.global.configMapNameOverride }}
  {{- $root := .root }}
  {{- range $name, $value := .container.env }}
    {{- $order := int ( default 0 $value.order ) -}}
    {{- if ( le $order 0 ) }}
      {{- include "application.oneEnv" ( dict "root" $root "name" $name "value" $value "configMapNameOverride" $configMapNameOverride ) | indent 2 -}}
    {{- end }}
  {{- end }}
  {{- range $name, $value := .container.env }}
    {{- $order := int ( default 0 $value.order ) -}}
    {{- if ( gt $order 0 ) }}
      {{- include "application.oneEnv" ( dict "root" $root "name" $name "value" $value "configMapNameOverride" $configMapNameOverride ) | indent 2 -}}
    {{- end }}
  {{- end }}
{{- end }}
terminationMessagePolicy: FallbackToLogsOnError
{{- with .container.resources }}
resources: {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .container.lifecycle }}
lifecycle: {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "application.podMetadata" -}}
labels: {{ include "common.selectorLabels" . | nindent 2 }}
{{- with .service.podLabels }}
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .service.podAnnotations }}
annotations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "application.secrets.dockerregistry" -}}
{
  "auths": {
    {{- range $registry, $conf := . }}
    {{ $registry | quote }}: {
      "auth": {{ (printf "%s:%s" $conf.username $conf.password) | b64enc | quote}},
      "username": {{ $conf.username | quote }},
      "password": {{ $conf.password | quote }},
      "email": {{ $conf.email | quote }}
    },
    {{- end }}
    "fix-end-comma": {"auth": ""}
  }
}
{{- end }}

{{- define "application.volumes" -}}
{{- $root := .root }}
{{- with .service.volumes }}
volumes:
{{- range $key, $value := . }}
  - name: {{ $key }}
    {{- if hasKey $value "secret" }}
    secret:
      {{- if eq ( default "self" $value.secret.secretName ) "self" }}
      secretName: {{ include "common.fullname" ( dict "root" $root "service" $root.Values.secrets ) }}
      {{- else }}
      {{- if eq ( default "self" $value.secret.secretName ) "self-metadata" }}
      secretName: {{ include "common.fullname" ( dict "root" $root "service" $root.Values "serviceName" "metadata" ) }}
      {{- else }}
      secretName: {{ $value.secret.secretName }}
      {{- end }}
      {{- end }}
      {{- with $value.secret.items }}
      items: {{- . | toYaml | nindent 6 }}
      {{- end }}
    {{- else }}
    {{- if hasKey $value "configMap" }}
    configMap:
      {{- if eq ( default "self" $value.configMap.name ) "self" }}
      name: {{ include "common.fullname" ( dict "root" $root "service" $root.Values.configMaps ) }}
      {{- else }}
      name: {{ $value.configMap.name }}
      {{- end }}
      {{- with $value.configMap.items }}
      items: {{- . | toYaml | nindent 6 }}
      {{- end }}
    {{- else }}
    {{- $value | toYaml | nindent 4 }}
    {{- end }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}
