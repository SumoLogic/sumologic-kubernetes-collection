resource "sumologic_field" "cluster" {
  field_name = "cluster"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "container" {
  field_name = "container"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "deployment" {
  field_name = "deployment"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "host" {
  field_name = "host"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "namespace" {
  field_name = "namespace"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "node" {
  field_name = "node"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "pod" {
  field_name = "pod"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "service" {
  field_name = "service"
  data_type = "String"
  state = "Enabled"
}
