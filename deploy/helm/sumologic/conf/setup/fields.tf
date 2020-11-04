resource "sumologic_field" "cluster" {
  count = var.create_fields ? 1 : 0

  field_name = "cluster"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "container" {
  count = var.create_fields ? 1 : 0

  field_name = "container"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "deployment" {
  count = var.create_fields ? 1 : 0

  field_name = "deployment"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "host" {
  count = var.create_fields ? 1 : 0

  field_name = "host"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "namespace" {
  count = var.create_fields ? 1 : 0

  field_name = "namespace"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "node" {
  count = var.create_fields ? 1 : 0

  field_name = "node"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "pod" {
  count = var.create_fields ? 1 : 0

  field_name = "pod"
  data_type = "String"
  state = "Enabled"
}

resource "sumologic_field" "service" {
  count = var.create_fields ? 1 : 0

  field_name = "service"
  data_type = "String"
  state = "Enabled"
}
