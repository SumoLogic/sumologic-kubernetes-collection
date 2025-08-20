#!/bin/bash
# Script to create minimal chart dependencies for testing when external repositories are not available
# This allows the helm template tests to run and reach the validation logic

set -euo pipefail

CHARTS_DIR="deploy/helm/sumologic/charts"
CHARTS=(
    "kube-prometheus-stack"
    "falco" 
    "metrics-server"
    "telegraf-operator"
    "tailing-sidecar-operator"
    "opentelemetry-operator"
    "prometheus-windows-exporter"
)

echo "Creating minimal chart dependencies for testing..."

# Remove existing charts directory and recreate
rm -rf "$CHARTS_DIR"
mkdir -p "$CHARTS_DIR"

# Create minimal Chart.yaml for each dependency
for chart in "${CHARTS[@]}"; do
    echo "Creating stub chart: $chart"
    mkdir -p "$CHARTS_DIR/$chart/templates"
    
    cat > "$CHARTS_DIR/$chart/Chart.yaml" << EOF
apiVersion: v2
name: $chart
version: 1.0.0
description: Minimal chart for testing
EOF
done

# Create kube-prometheus-stack helpers needed by sumologic templates
cat > "$CHARTS_DIR/kube-prometheus-stack/templates/_helpers.tpl" << 'EOF'
{{/* 
kube-prometheus-stack helpers for testing
*/}}
{{- define "kube-prometheus-stack.namespace" -}}
{{ .Values.namespaceOverride | default .Release.Namespace }}
{{- end -}}

{{- define "kube-prometheus-stack.name" -}}
kube-prometheus-stack
{{- end -}}

{{- define "kube-prometheus-stack.labels" -}}
app.kubernetes.io/name: kube-prometheus-stack
{{- end -}}
EOF

echo "Minimal chart dependencies created successfully!"
echo "Note: These are minimal stubs for testing only. The charts/ directory is in .gitignore and won't be committed."