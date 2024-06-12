resource "sumologic_field" "collection_field" {
  for_each = var.create_fields ? toset(var.fields) : toset([])

  lifecycle {
    # ignore changes for name and type, as older installations have been case sensitive
    # see: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/2865
    ignore_changes = [field_name, data_type]
  }

  field_name = "${ each.key }"
  data_type = "String"
  state = "Enabled"
}
