# Built-in application port profiles referenced by DNAT rules
data "vcd_nsxt_app_port_profile" "system" {
  for_each = toset([for r in var.dnat_rules : r.app_port_profile if r.app_port_profile != null])

  name       = each.value
  scope      = "SYSTEM"
  context_id = var.vdc_id
}

# DNAT: external_address (public) -> internal_address (VM)
resource "vcd_nsxt_nat_rule" "dnat" {
  for_each = var.dnat_rules

  org             = var.org
  edge_gateway_id = var.edge_gateway_id
  rule_type       = "DNAT"
  name            = coalesce(each.value.name, each.key)
  description     = each.value.description
  enabled         = each.value.enabled
  logging         = each.value.logging

  external_address    = each.value.external_address
  internal_address    = each.value.internal_address
  dnat_external_port  = each.value.dnat_external_port
  app_port_profile_id = each.value.app_port_profile != null ? data.vcd_nsxt_app_port_profile.system[each.value.app_port_profile].id : null

  firewall_match = each.value.firewall_match
  priority       = each.value.priority
}

# SNAT: internal_address (source network) -> external_address (public)
resource "vcd_nsxt_nat_rule" "snat" {
  for_each = var.snat_rules

  org             = var.org
  edge_gateway_id = var.edge_gateway_id
  rule_type       = "SNAT"
  name            = coalesce(each.value.name, each.key)
  description     = each.value.description
  enabled         = each.value.enabled
  logging         = each.value.logging

  external_address         = each.value.external_address
  internal_address         = each.value.internal_address
  snat_destination_address = each.value.snat_destination_address

  firewall_match = each.value.firewall_match
  priority       = each.value.priority
}
