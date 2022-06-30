provider "sumologic" {}

provider "kubernetes" {
{{- $ctx := .Values -}}
{{ $printf_str := "%-25s" }}
{{ range $key, $value := .Values.sumologic.cluster }}
  {{ if eq $key "exec" }}
  exec {
    command = "{{ $ctx.sumologic.cluster.exec.command }}"
    {{ if hasKey $ctx.sumologic.cluster.exec "api_version" }}{{ printf $printf_str "api_version" }} = "{{ $ctx.sumologic.cluster.exec.api_version }}"{{ end }}
    {{ if hasKey $ctx.sumologic.cluster.exec "args" }}
    {{ printf $printf_str "args" }} = {{ toJson $ctx.sumologic.cluster.exec.args }}
    {{- end -}}
    {{ if hasKey $ctx.sumologic.cluster.exec "env" }}
    {{ printf $printf_str "env" }} = {
      {{ range $key_env, $value_env := $ctx.sumologic.cluster.exec.env }}
        {{ printf $printf_str $key_env }} = {{ include "terraform.print_value" $value_env }}
      {{- end }}
    }
    {{ end }}
  }
  {{- else if not (eq $key "load_config_file") -}}
  {{ printf "  %-25s" $key }} = {{ include "terraform.print_value" $value }}
  {{- end }}
{{- end }}
}