{{/*
Expand the name of the chart.
*/}}
{{- define "nkp-2.17.1.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nkp-2.17.1.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "nkp-2.17.1.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nkp-2.17.1.labels" -}}
helm.sh/chart: {{ include "nkp-2.17.1.chart" . }}
{{ include "nkp-2.17.1.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nkp-2.17.1.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nkp-2.17.1.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nkp-2.17.1.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nkp-2.17.1.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
etcd EncryptionConfig used by the etcd-encryption-config Secret (templates/secrets.yaml),
consumed by KubeadmControlPlane via encryption-provider-config (templates/cluster.yaml).
*/}}
{{- define "nkp-2.17.1.etcdEncryptionConfig" -}}
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
      - configmaps
    providers:
      - aescbc:
          keys:
            - name: key
              secret: {{ required "cluster.etcd.encryptionKey is required: generate a 32-byte AES-CBC key with `head -c 32 /dev/urandom | base64` and supply it via -f/--set" .Values.cluster.etcd.encryptionKey }}
      - identity: {}
{{- end }}

{{/*
Containerd registry mirror config.toml used by the control-plane and worker
containerd-configuration Secrets (templates/secrets.yaml).
*/}}
{{- define "nkp-2.17.1.containerdMirrorConfig" -}}
# override all the mirrors configuration
# Containerd automatically appends mirrors."docker.io"
# need to explicitly override mirrors."docker.io" with the mirror to pull images from dockerhub
[plugins."io.containerd.grpc.v1.cri".registry]
  # config path and mirrors cannot be both set
  config_path = ""
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
    endpoint = ["https://{{ .Values.cluster.containerd.registryMirror.host }}","https://registry-1.docker.io"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."*"]
    endpoint = ["https://{{ .Values.cluster.containerd.registryMirror.host }}"]
[plugins."io.containerd.grpc.v1.cri".registry.configs."{{ .Values.cluster.containerd.registryMirror.host }}".tls]
  ca_file = "{{ .Values.cluster.containerd.registryMirror.caFile }}"
{{- end }}
