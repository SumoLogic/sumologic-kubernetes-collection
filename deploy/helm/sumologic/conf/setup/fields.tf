{{- range $value := .Values.sumologic.logs.fields }}
resource "sumologic_field" {{ $value | quote }} {
  count = var.create_fields ? 1 : 0

  lifecycle {
    ignore_changes = [field_name, data_type]
  }

  field_name = {{ $value | quote }}
  data_type = "String"
  state = "Enabled"
}
{{- end }}
