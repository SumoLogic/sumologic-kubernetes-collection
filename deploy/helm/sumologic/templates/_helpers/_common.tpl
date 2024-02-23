{{/*
Expand the name of the chart.
*/}}
{{- define "sumologic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 22 chars because some Kubernetes name fields are limited to 63 characters (by the DNS naming spec).
In particular, some statefulsets will have too long names if the name is longer than 22 characters.
*/}}
{{- define "sumologic.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 22 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 22 | trimSuffix "-" }}
{{- end -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden
*/}}
{{- define "sumologic.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Create default fully qualified labels.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sumologic.labels.app" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.clusterrole" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.clusterrolebinding" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.opentelemetry.operator" -}}
{{- template "sumologic.fullname" . }}-ot-operator
{{- end -}}

{{- define "sumologic.labels.app.opentelemetry.operator.instrumentation" -}}
{{- template "sumologic.labels.app.opentelemetry.operator" . }}-instr
{{- end -}}

{{- define "sumologic.labels.app.opentelemetry.operator.instrumentation.configmap" -}}
{{- template "sumologic.labels.app.opentelemetry.operator.instrumentation" . }}-cm
{{- end -}}

{{- define "sumologic.labels.app.opentelemetry.operator.instrumentation.job" -}}
{{- template "sumologic.labels.app.opentelemetry.operator.instrumentation" . }}
{{- end -}}

{{- define "sumologic.metadata.name.opentelemetry.operator" -}}
{{ template "sumologic.fullname" . }}-ot-operator
{{- end -}}

{{- define "sumologic.metadata.name.opentelemetry.operator.instrumentation" -}}
{{ template "sumologic.metadata.name.opentelemetry.operator" . }}-instr
{{- end -}}

{{- define "sumologic.metadata.name.opentelemetry.operator.instrumentation.configmap" -}}
{{ template "sumologic.metadata.name.opentelemetry.operator.instrumentation" . }}-cm
{{- end -}}

{{- define "sumologic.metadata.name.opentelemetry.operator.instrumentation.job" -}}
{{ template "sumologic.metadata.name.opentelemetry.operator.instrumentation" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup" -}}
{{- template "sumologic.labels.app" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.job" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.configmap" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.configmap-custom" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.role" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.rolebinding" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.serviceaccount" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-setup-scc
{{- end -}}

{{- define "sumologic.labels.app.setup.secret" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.secret" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-scc
{{- end -}}

{{- define "sumologic.labels.app.cleanup" -}}
{{- template "sumologic.labels.app" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.configmap" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.role" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.rolebinding" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.serviceaccount" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.machineconfig.worker" -}}
{{- template "sumologic.fullname" . }}-worker-extensions
{{- end -}}

{{- define "sumologic.labels.machineconfig.worker" -}}
machineconfiguration.openshift.io/role: worker
{{- end -}}

{{- define "sumologic.labels.app.machineconfig.master" -}}
{{- template "sumologic.fullname" . }}-master-extensions
{{- end -}}

{{- define "sumologic.labels.machineconfig.master" -}}
machineconfiguration.openshift.io/role: master
{{- end -}}

{{/*
Generate cleanup job helm.sh annotations. It takes weight as parameter.

Example usage:

{{ include "sumologic.annotations.app.cleanup.helmsh" "1" }}

*/}}
{{- define "sumologic.annotations.app.cleanup.helmsh" -}}
helm.sh/hook: pre-delete
helm.sh/hook-weight: {{ printf "\"%s\"" . }}
helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
{{- end -}}

{{/*
Generate setup job helm.sh annotations. It takes weight as parameter.

Example usage:

{{ include "sumologic.annotations.app.setup.helmsh" "1" }}

*/}}
{{- define "sumologic.annotations.app.setup.helmsh" -}}
helm.sh/hook: pre-install,pre-upgrade
helm.sh/hook-weight: {{ printf "\"%s\"" . }}
helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
{{- end -}}

{{- define "sumologic.metadata.name.roles.clusterrole" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.roles.clusterrolebinding" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-scc
{{- end -}}

{{- define "sumologic.metadata.name.setup" -}}
{{ template "sumologic.fullname" . }}-setup
{{- end -}}

{{- define "sumologic.metadata.name.setup.job" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.configmap-custom" -}}
{{ template "sumologic.metadata.name.setup" . }}-custom
{{- end -}}

{{- define "sumologic.metadata.name.setup.configmap" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.role" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.rolebinding" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.serviceaccount" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.securitycontextconstraints" -}}
{{- template "sumologic.metadata.name.setup" . }}-scc
{{- end -}}

{{- define "sumologic.metadata.name.setup.secret" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup" -}}
{{ template "sumologic.fullname" . }}-cleanup
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.configmap" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.role" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.rolebinding" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.serviceaccount" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.secret" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.priorityclass" -}}
{{ template "sumologic.fullname" . }}-priorityclass
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner" -}}
{{- template "sumologic.fullname" . }}-pvc-cleaner
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner.configmap" -}}
{{- template "sumologic.metadata.name.pvcCleaner" . }}
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner" -}}
pvc-cleaner
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner.configmap" -}}
{{- template "sumologic.labels.app.pvcCleaner" . }}
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}-pvc-cleaner
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}-pvc-cleaner
{{- end -}}

{{/*
Return the otelcol metadata enrichment image
*/}}
{{- define "sumologic.metadata.image" -}}
{{ template "utils.getOtelImage" (dict "overrideImage" .Values.metadata.image "defaultImage" .Values.sumologic.otelcolImage) }}
{{- end -}}

{{/*
Create common labels used throughout the chart.
If dryRun=true, we do not create any chart labels.
*/}}
{{- define "sumologic.labels.common" -}}
{{- if .Values.dryRun -}}
{{- else -}}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: "{{ .Release.Name }}"
heritage: "{{ .Release.Service }}"
{{- end -}}
{{- end -}}

{{/*
Returns sumologic version string
*/}}
{{- define "sumologic.sumo_client" -}}
k8s_{{ .Chart.Version }}
{{- end -}}

{{/*
Returns clusterName with spaces replaced with dashes
*/}}
{{- define "sumologic.clusterNameReplaceSpaceWithDash" -}}
{{ .Values.sumologic.clusterName | replace " " "-"}}
{{- end -}}

{{/*
Returns the otelcol image given two image dicts of the form {"repository": "...", "tag"}
The first block is for defaults, and the second for overrides.
For both the image repository and tag, the override will be used if present, otherwise the default will be used.
This is a helper method for ensuring the global default image is used where appropriate.

Example usage:

{{ template "utils.getOtelImage" (dict "overrideImage" .Values.tracesSampler.deployment.image "defaultImage" .Values.sumologic.otelcolImage) }}
*/}}
{{- define "utils.getOtelImage" -}}
{{- $defaultRepository := .defaultImage.repository -}}
{{- $defaultTag := .defaultImage.tag -}}
{{- $addFipsSuffix := .defaultImage.addFipsSuffix | default false -}}
{{- $repositoryOverride := .overrideImage.repository -}}
{{- $tagOverride:= .overrideImage.tag -}}
{{- $repository := $repositoryOverride | default $defaultRepository -}}
{{- $tag := $tagOverride | default $defaultTag -}}
{{- $tag := $addFipsSuffix | ternary (printf "%s-%s" $tag "fips") $tag -}}
{{- printf "%s:%s" $repository $tag | quote }}
{{- end -}}

{{/*
Get configuration value, otherwise returns default

Example usage:

{{ include "utils.get_default" (dict "Values" .Values "Keys" (list "key1" "key2") "Default" "default_value") | quote }}

It returns `.Value.key1.key2` if it exists otherwise `default_value`

*/}}
{{- define "utils.get_default" -}}
{{- $dict := .Values -}}
{{- $keys := .Keys -}}
{{- $default := .Default -}}
{{- $success := true }}
{{- range $keys -}}
  {{- if (and $success (hasKey $dict .)) }}
    {{- $dict = index $dict . }}
  {{- else }}
    {{- $success = false }}
  {{- end }}
{{- end }}
{{- if $success }}
  {{- $dict }}
{{- else }}
  {{- $default }}
{{- end }}
{{- end -}}



{{/*
Generate envs for given source type:

Example:

{{ include "kubernetes.sources.envs" (dict "Context" .Values "Type" "metrics")}}
*/}}
{{- define "kubernetes.sources.envs" -}}
{{- $ctx := .Context -}}
{{- $type := .Type -}}
{{- range $name, $source := (index .Context.sumologic.collector.sources $type) -}}
{{/* 
This is a slight hack to prevent otlp sources from being added as env variables if they're not enabled.
As a result, the user can upgrade without enabling setup until they actually enable otlp sources.
*/}}
{{- $signalTypeConfig := index $ctx.sumologic $type -}}
{{- $signalSourceType := $signalTypeConfig.sourceType | default "http" -}}
{{- $sourceContentType := (($source).properties).content_type | default "" -}}
{{- if or (ne $sourceContentType "Otlp") (eq $signalSourceType "otlp") -}}
{{- include "kubernetes.sources.env" (dict "Context" $ctx "Type" $type  "Name" $name ) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate envs for given source type:

Example:

{{ include "kubernetes.sources.env" (dict "Context" .Values "Type" "metrics" "Name" $name ) }}
*/}}
{{ define "kubernetes.sources.env" }}
{{- $ctx := .Context -}}
{{- $type := .Type -}}
{{- $name := .Name -}}
- name: {{ template "terraform.sources.endpoint" (include "terraform.sources.name" (dict "Name" $name "Type" $type)) }}
  valueFrom:
    secretKeyRef:
      name: sumologic
      key: {{ template "terraform.sources.config-map-variable" (dict "Type" $type "Context" $ctx "Name" $name) }}
{{ end }}


{{/*
Generate a space separated list of quoted values:

Example:

{{ include "helm-toolkit.utils.joinListWithSpaces" .Values.sumologic.logs.fields }}
*/}}
{{- define "helm-toolkit.utils.joinListWithSpaces" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}
{{- if not $local.first }} {{ end -}}
{{- $v | quote -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
{{- end -}}


{{/*
Returns kubernetes minor version as integer (without additional chars like +)

Example:

{{ include "kubernetes.minor" . }}
*/}}
{{- define "kubernetes.minor" -}}
{{- print (regexFind "^\\d+" .Capabilities.KubeVersion.Minor) -}}
{{- end -}}

{{/*
Returns default node selector for all objects.

Example:

{{ include "kubernetes.defaultNodeSelector" . }}
*/}}
{{- define "kubernetes.defaultNodeSelector" -}}
{{- if .Values.sumologic.nodeSelector -}}
{{- toYaml .Values.sumologic.nodeSelector -}}
{{- end -}}
{{- end -}}

{{/*
Returns default tolerations for all objects.

Example:

{{ include "kubernetes.defaultTolerations" . }}
*/}}
{{- define "kubernetes.defaultTolerations" -}}
{{- if .Values.sumologic.tolerations -}}
{{- toYaml .Values.sumologic.tolerations -}}
{{- end -}}
{{- end -}}

{{/*
Returns default affinity for all objects.

Example:

{{ include "kubernetes.defaultAffinity" . }}
*/}}
{{- define "kubernetes.defaultAffinity" -}}
{{- if .Values.sumologic.affinity -}}
{{- toYaml .Values.sumologic.affinity -}}
{{- end -}}
{{- end -}}

{{/*
Environment variables used to configure the HTTP proxy for programs using
Go's net/http. See: https://pkg.go.dev/net/http#RoundTripper

Example Usage:
'{{ include "proxy-env-variables" . }}'
*/}}
{{- define "proxy-env-variables" -}}
{{- if .Values.sumologic.httpProxy }}
- name: HTTP_PROXY
  value: {{ .Values.sumologic.httpProxy }}
{{- end -}}
{{- if .Values.sumologic.httpsProxy }}
- name: HTTPS_PROXY
  value: {{ .Values.sumologic.httpsProxy }}
{{- end -}}
{{- if .Values.sumologic.noProxy }}
- name: NO_PROXY
  value: {{ .Values.sumologic.noProxy }}
{{- end -}}
{{- end -}}

{{/*
Pod anti affinity "hard"

'{{ include "pod-anti-affinity-hard" . }}'
*/}}
{{- define "pod-anti-affinity-hard" -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app
        operator: In
        values:
{{- if eq (include "logs.enabled" .) "true" }}
        - {{ template "sumologic.labels.app.logs.pod" . }}
{{- end }}
{{- if eq (include "metrics.enabled" .) "true" }}
        - {{ template "sumologic.labels.app.metrics.pod" . }}
{{- end }}
{{- if eq (include "events.enabled" .) "true" }}
        - {{ template "sumologic.labels.app.events.pod" . }}
{{- end }}
        - {{ template "sumologic.labels.app.otelcolinstrumentation.pod" . }}
      - key: app
        operator: In
        values:
        - prometheus-operator-prometheus
    topologyKey: "kubernetes.io/hostname"
{{- end -}}

{{/*
Pod anti affinity "soft"

'{{ include "pod-anti-affinity-soft" . }}'
*/}}
{{- define "pod-anti-affinity-soft" -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
{{- if eq (include "logs.enabled" .) "true" }}
          - {{ template "sumologic.labels.app.logs.pod" . }}
{{- end }}
{{- if eq (include "metrics.enabled" .) "true" }}
          - {{ template "sumologic.labels.app.metrics.pod" . }}
{{- end }}
{{- if eq (include "events.enabled" .) "true" }}
          - {{ template "sumologic.labels.app.events.pod" . }}
{{- end }}
          - {{ template "sumologic.labels.app.otelcolinstrumentation.pod" . }}
        - key: app
          operator: In
          values:
          - prometheus-operator-prometheus
      topologyKey: "kubernetes.io/hostname"
{{- end -}}

{{/*
Returns whether autoscaling is enabled. 
Returns value of received parameter (.autoscalingEnabled) if defined, 
otherwise returns value of global flag (.Values.sumologic.autoscaling.enabled).

Example usage:
{{- template "is.autoscaling.enabled" (dict "autoscalingEnabled" .Values.metadata.logs.autoscaling.enabled "Values" .Values) }}
*/}}
{{- define "is.autoscaling.enabled" -}}
{{- if kindIs "bool" .autoscalingEnabled -}}
  {{- .autoscalingEnabled -}}
{{- else }}
  {{- .Values.sumologic.autoscaling.enabled -}}
{{- end }}
{{- end -}}

{{- define "nodeSelector" -}}
{{- $nodeSelector := dict "kubernetes.io/os" "linux" -}}
{{- if .nodeSelector -}}
{{- $nodeSelector = mergeOverwrite $nodeSelector .nodeSelector -}}
{{- else if .Values.sumologic.nodeSelector -}}
{{- $nodeSelector = mergeOverwrite $nodeSelector .Values.sumologic.nodeSelector -}}
{{- end -}}
{{- toYaml $nodeSelector -}}
{{- end -}}

{{- define "pvcCleaner.job.nodeSelector" -}}
{{- template "nodeSelector" (dict "Values" .Values "nodeSelector" .Values.pvcCleaner.job.nodeSelector)}}
{{- end -}}

{{- define "pvcCleaner.job.tolerations" -}}
{{- if .Values.pvcCleaner.job.tolerations -}}
{{- toYaml .Values.pvcCleaner.job.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "pvcCleaner.job.affinity" -}}
{{- if .Values.pvcCleaner.job.affinity -}}
{{- toYaml .Values.pvcCleaner.job.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}

{{- define "sumologic.sumologic-mock.name.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}-mock
{{- end -}}

{{- define "useDefaultConfig" }}
{{/*
This function checks if any keys other than 'merge' and 'override' exist in a given map.
It takes a map as an argument and returns true if extra keys are found, else false.

Example usage:
{{ $useValuesYamlConfig := include "useDefaultConfig" .Values.tracesSampler.config | trim }}
*/}}
{{- $map := . -}}
{{- $extraKeysExist := false -}}
{{- range $key, $_ := $map }}
  {{- if and (ne $key "merge") (ne $key "override") }}
    {{- $extraKeysExist = true -}}
  {{- end }}
{{- end }}
{{- if $extraKeysExist }}
true
{{- else }}
false
{{- end }}
{{- end }}

{{- define "removeMergeAndOverrideKeys" -}}
{{/*
This function removes keys 'merge' and 'override' in a given map.
It takes a map as an argument and returns new map without 'merge' and 'override' keys.

Example usage:
{{ $finalConfig = include "removeMergeAndOverrideKeys" .Values.tracesSampler.config }}
*/}}
{{- $originalMap := . -}}
{{- $newMap := dict -}}
{{- range $key, $value := $originalMap -}}
  {{- if and (ne $key "merge") (ne $key "override") -}}
    {{- $_ := set $newMap $key $value -}}
  {{- end -}}
{{- end -}}
{{ toYaml $newMap }}
{{- end -}}
