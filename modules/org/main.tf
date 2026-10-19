resource "vcd_org" "this" {
  name        = var.name
  full_name   = var.full_name
  description = var.description

  is_enabled = var.is_enabled
}
