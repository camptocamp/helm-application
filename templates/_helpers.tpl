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
      {{ if and ( hasKey .value "name" ) ( eq .value.name "self" ) -}}
      {{ if .value.type | eq "configMap" -}}
      name: {{ include "common.fullname" ( dict "root" .root "service" .root.Values.configMaps ) }}
      {{ else -}}
      name: {{ include "common.fullname" ( dict "root" .root "service" .root.Values.secrets ) }}
      {{ end -}}
      {{ else if hasPrefix "self-external-secret-" .value.name -}}
      {{- $name := substr 21 -1 .value.name }}
      {{- $definition := get .root.Values.externalSecrets $name }}
      name: {{ include "common.fullname" ( dict "root" .root "service" $definition "serviceName" $name ) }}
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
{{- $args := . }}

{{- if .root.Values.global.image.pullSecrets }}
imagePullSecrets:
{{- toYaml .root.Values.global.image.pullSecrets | nindent 2 }}
{{- else }}
{{- if .root.Values.dockerregistry -}}
{{- if .root.Values.dockerregistry.enabled -}}
imagePullSecrets:
  - name: {{ include "common.fullname" ( dict "root" .root "service" .root.Values "serviceName" "dockerregistry" ) }}
{{- end }}
{{- end }}
{{- end }}
serviceAccountName: {{ include "application.serviceAccountName" ( .root ) }}
securityContext: {{- toYaml .root.Values.podSecurityContext | nindent 2 }}
{{- with .service.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}

{{- with .service.affinity }}
affinity:
{{- with .podAntiAffinity }}
{{- if hasKey . "topologyKey" }}
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
{{- if hasKey . "labelSelector" }}
            {{- range $key, $value := .labelSelector }}
            - key: {{ $key }}
              operator: In
              values:
                - {{ $value | quote}}
            {{- end }}
{{- else }}
            - key: app.kubernetes.io/name
              operator: In
              values:
                - {{ include "common.name" $args }}
            - key: app.kubernetes.io/instance
              operator: In
              values:
                - {{ $args.root.Release.Name }}
            - key: app.kubernetes.io/component
              operator: In
              values:
{{- if hasKey $args.service "serviceName" }}
                - {{ printf "%s" $args.service.serviceName }}
{{- else if hasKey $args "serviceName" }}
                - {{ printf "%s" $args.serviceName }}
{{- else }}
                - main
{{- end }}
{{- end }}  {{/*  if hasKey . "labelSelector" */}}
        topologyKey: {{ .topologyKey | quote }}
{{- else }}
podAntiAffinity: {{ toYaml . | nindent 4 }}
{{- end }}  {{/*  if hasKey . "topologyKey" */}}
{{- end }}  {{/*  with .podAntiAffinity */}}
{{- with .podAffinity }}
  podAffinity: {{ toYaml . | nindent 4 }}
{{- end }}
{{- with .nodeAffinity }}
  nodeAffinity: {{ toYaml . | nindent 4 }}
{{- end }}
{{- end }}  {{/*  with .service.affinity */}}

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
    {{ $conf.url | quote }}: {
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

{{- define "application.secrets.externaldockerregistry" -}}
{
  "auths": {
    {{- range $registryName, $conf := . }}
    {{- $url := ( default ( printf "{{ .%s_url }}" $registryName ) $conf.url ) }}
    {{- $username := ( default ( printf "{{ .%s_username }}" $registryName ) $conf.username ) }}
    {{- $password := ( default ( printf "{{ .%s_password }}" $registryName ) $conf.password ) }}
    {{- $email := ( default ( printf "{{ .%s_email }}" $registryName ) $conf.email ) }}
    {{ $url | quote }}: {
      {{- if and ( hasKey $conf "username" ) ( hasKey $conf "password" ) }}
      "auth": {{ printf "%s:%s" $conf.username $conf.password | b64enc | quote }},
      {{- else if hasKey $conf "username" }}
      "auth": {{ printf "{{ ( printf \"%s:%s\" .%s_password ) | b64enc | quote }}" $conf.username "%s" $registryName }},
      {{- else if hasKey $conf "password" }}
      "auth": {{ printf "{{ ( printf \"%s:%s\" .%s_username ) | b64enc | quote }}" "%s" $conf.password $registryName }},
      {{- else }}
      "auth": {{ printf "{{ ( printf \"%s:%s\" .%s_username .%s_password ) | b64enc | quote }}" "%s" "%s" $registryName $registryName }},
      {{- end }}
      "username": {{ $username | quote }},
      "password": {{ $password | quote }},
      "email": {{ $email | quote }}
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
      {{- else if hasPrefix "self-external-secret-" $value.secret.secretName }}
      {{- $name := substr 21 -1 $value.secret.secretName }}
      {{- $definition := get $root.Values.externalSecrets $name }}
      secretName: {{ include "common.fullname" ( dict "root" $root "service" $definition "serviceName" $name ) }}
      {{- else }}
      secretName: {{ $value.secret.secretName }}
      {{- end }}
      {{- with $value.secret.items }}
      items: {{- . | toYaml | nindent 6 }}
      {{- end }}
    {{- else }}
    {{- if hasKey $value "configMap" }}
    configMap:
      {{- if eq ( default "self" $value.configMap.name ) "self" }}
      name: {{ include "common.fullname" ( dict "root" $root "service" $root.Values.configMaps ) }}
      {{- else if eq ( default "self" $value.configMap.name ) "self-metadata" }}
      name: {{ include "common.fullname" ( dict "root" $root "service" $root.Values "serviceName" "metadata" ) }}
      {{- else }}
      name: {{ default $value.configMap.name ( get $root.Values.global.configMapNameOverride $value.configMap.name ) | quote }}
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
