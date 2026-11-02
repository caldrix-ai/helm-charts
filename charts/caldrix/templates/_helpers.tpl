{{/*
The chart's name, truncated to the 63 characters a DNS label allows.
*/}}
{{- define "caldrix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The full name: fullnameOverride, else the release name when it already contains the chart's name, else
<release>-<name>; truncated to 63 characters.
*/}}
{{- define "caldrix.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
The chart label: <name>-<version>.
*/}}
{{- define "caldrix.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The common labels.
*/}}
{{- define "caldrix.labels" -}}
helm.sh/chart: {{ include "caldrix.chart" . }}
{{ include "caldrix.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
The selector labels.
*/}}
{{- define "caldrix.selectorLabels" -}}
app.kubernetes.io/name: {{ include "caldrix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
The ServiceAccount's name.
*/}}
{{- define "caldrix.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "caldrix.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
The image reference: <repository>@<digest> when image.digest is set, else <repository>:<tag>, the tag
defaulting to <appVersion>-cpu.
*/}}
{{- define "caldrix.image" -}}
{{- if .Values.image.digest }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (default (printf "%s-cpu" .Chart.AppVersion) .Values.image.tag) }}
{{- end }}
{{- end }}

{{/*
The container's args, a YAML list: serve <model> --host 0.0.0.0 --port 8425 --backend <backend>, then
--ctx <context> when set, then model.extraArgs verbatim. Each value is one element.
*/}}
{{- define "caldrix.args" -}}
{{- $args := list "serve" (toString .Values.model.name) "--host" "0.0.0.0" "--port" "8425" "--backend" .Values.model.backend }}
{{- with .Values.model.context }}
{{- $args = concat $args (list "--ctx" (toString .)) }}
{{- end }}
{{- $args = concat $args .Values.model.extraArgs }}
{{- toYaml $args }}
{{- end }}

{{/*
The values rules that fail the render by name (the GPU, replica and secret rules).
*/}}
{{- define "caldrix.validate" -}}
{{- if and (or .Values.gpu.enabled (eq .Values.model.backend "hip")) (not .Values.image.gpu) }}
{{- fail "caldrix: gpu.enabled and model.backend hip need image.gpu: true (your statement that the image at image.repository carries a GPU lane); the ROCm image is not published yet and the default image is the CPU one" }}
{{- end }}
{{- if and (gt (int .Values.replicaCount) 1) .Values.persistence.enabled (not (has "ReadWriteMany" .Values.persistence.accessModes)) }}
{{- fail "caldrix: replicaCount above 1 needs persistence.accessModes to include ReadWriteMany, or persistence.enabled: false (one ReadWriteOnce volume has one writer)" }}
{{- end }}
{{- if and .Values.huggingface.token .Values.huggingface.existingSecret }}
{{- fail "caldrix: set huggingface.token or huggingface.existingSecret, not both" }}
{{- end }}
{{- end }}
