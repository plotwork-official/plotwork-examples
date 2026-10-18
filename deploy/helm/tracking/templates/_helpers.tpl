{{- define "parcelpoint.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}{{ .Release.Name | trunc 63 }}{{ else }}{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 }}{{ end }}
{{- end }}

{{- define "parcelpoint.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "parcelpoint.labels" -}}
{{ include "parcelpoint.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}
