{{- range $value := .Values.sumologic.logs.fields }}
resource "sumologic_field" {{ $value | quote }} {
  count = var.create_fields ? 1 : 0

  field_name = {{ $value | quote }}
  data_type = "String"
  state = "Enabled"
}
{{- end }}
