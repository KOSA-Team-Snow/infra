resource "random_string" "name_suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}
