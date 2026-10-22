# Named IP sets. vcd_nsxt_nat_rule only accepts a plain IP/CIDR string, so a
# rule that references a set gets the set's single address (see locals).
resource "vcd_nsxt_ip_set" "this" {
  for_each = var.ip_sets

  org             = var.org
  edge_gateway_id = var.edge_gateway_id
  name            = coalesce(each.value.name, each.key)
  description     = each.value.description
  ip_addresses    = each.value.ip_addresses
}

locals {
  # IP set key -> its only address. Sets with several entries can't back a NAT
  # address and are left out; the rule preconditions report a bad reference.
  ip_set_address = { for k, s in vcd_nsxt_ip_set.this : k => one(s.ip_addresses) if length(s.ip_addresses) == 1 }

  # Referenced IP set keys per rule, for the existence/size precondition.
  dnat_ip_set_refs = { for k, r in var.dnat_rules : k => [for s in [r.external_ip_set, r.internal_ip_set] : s if s != null] }
  snat_ip_set_refs = { for k, r in var.snat_rules : k => [for s in [r.external_ip_set, r.internal_ip_set, r.snat_destination_ip_set] : s if s != null] }
}

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

  external_address    = each.value.external_ip_set != null ? lookup(local.ip_set_address, each.value.external_ip_set, null) : each.value.external_address
  internal_address    = each.value.internal_ip_set != null ? lookup(local.ip_set_address, each.value.internal_ip_set, null) : each.value.internal_address
  dnat_external_port  = each.value.dnat_external_port
  app_port_profile_id = each.value.app_port_profile != null ? data.vcd_nsxt_app_port_profile.system[each.value.app_port_profile].id : null

  firewall_match = each.value.firewall_match
  priority       = each.value.priority

  lifecycle {
    precondition {
      condition     = (each.value.external_address == null) != (each.value.external_ip_set == null)
      error_message = "DNAT rule \"${each.key}\": set exactly one of external_address or external_ip_set."
    }
    precondition {
      condition     = (each.value.internal_address == null) != (each.value.internal_ip_set == null)
      error_message = "DNAT rule \"${each.key}\": set exactly one of internal_address or internal_ip_set."
    }
    precondition {
      condition     = alltrue([for s in local.dnat_ip_set_refs[each.key] : contains(keys(local.ip_set_address), s)])
      error_message = "DNAT rule \"${each.key}\": every referenced IP set must exist in ip_sets and contain exactly one IP or CIDR."
    }
  }
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

  external_address         = each.value.external_ip_set != null ? lookup(local.ip_set_address, each.value.external_ip_set, null) : each.value.external_address
  internal_address         = each.value.internal_ip_set != null ? lookup(local.ip_set_address, each.value.internal_ip_set, null) : each.value.internal_address
  snat_destination_address = each.value.snat_destination_ip_set != null ? lookup(local.ip_set_address, each.value.snat_destination_ip_set, null) : each.value.snat_destination_address

  firewall_match = each.value.firewall_match
  priority       = each.value.priority

  lifecycle {
    precondition {
      condition     = (each.value.external_address == null) != (each.value.external_ip_set == null)
      error_message = "SNAT rule \"${each.key}\": set exactly one of external_address or external_ip_set."
    }
    precondition {
      condition     = (each.value.internal_address == null) != (each.value.internal_ip_set == null)
      error_message = "SNAT rule \"${each.key}\": set exactly one of internal_address or internal_ip_set."
    }
    precondition {
      condition     = each.value.snat_destination_address == null || each.value.snat_destination_ip_set == null
      error_message = "SNAT rule \"${each.key}\": set at most one of snat_destination_address or snat_destination_ip_set."
    }
    precondition {
      condition     = alltrue([for s in local.snat_ip_set_refs[each.key] : contains(keys(local.ip_set_address), s)])
      error_message = "SNAT rule \"${each.key}\": every referenced IP set must exist in ip_sets and contain exactly one IP or CIDR."
    }
  }
}
