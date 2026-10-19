# NSX-T firewall rules reference firewall groups (IP sets) and application
# port profiles by ID, so those are derived from the plain rule inputs here.
locals {
  ip_sets = merge(
    { for r in var.rules : "${r.name}-src" => r.source_ip_addresses if length(r.source_ip_addresses) > 0 },
    { for r in var.rules : "${r.name}-dst" => r.destination_ip_addresses if length(r.destination_ip_addresses) > 0 },
  )

  system_profiles = toset(flatten([for r in var.rules : r.app_port_profiles]))
  custom_profiles = { for r in var.rules : r.name => r.custom_ports if length(r.custom_ports) > 0 }
}

resource "vcd_nsxt_ip_set" "this" {
  for_each = local.ip_sets

  org             = var.org
  edge_gateway_id = var.edge_gateway_id
  name            = each.key
  ip_addresses    = each.value
}

# Built-in profiles such as "SSH", "HTTP", "HTTPS", "ICMP ALL"
data "vcd_nsxt_app_port_profile" "system" {
  for_each = local.system_profiles

  name       = each.value
  scope      = "SYSTEM"
  context_id = var.vdc_id
}

resource "vcd_nsxt_app_port_profile" "custom" {
  for_each = local.custom_profiles

  org        = var.org
  context_id = var.vdc_id
  name       = "${each.key}-ports"
  scope      = "TENANT"

  dynamic "app_port" {
    for_each = each.value
    content {
      protocol = upper(app_port.value.protocol)
      port     = app_port.value.ports
    }
  }
}

# Manages the full, ordered rule list of the edge gateway (needs at least one rule)
resource "vcd_nsxt_firewall" "this" {
  count = length(var.rules) > 0 ? 1 : 0

  org             = var.org
  edge_gateway_id = var.edge_gateway_id

  dynamic "rule" {
    for_each = var.rules
    content {
      name        = rule.value.name
      action      = rule.value.action
      direction   = rule.value.direction
      ip_protocol = rule.value.ip_protocol
      enabled     = rule.value.enabled
      logging     = rule.value.logging

      source_ids      = length(rule.value.source_ip_addresses) > 0 ? [vcd_nsxt_ip_set.this["${rule.value.name}-src"].id] : null
      destination_ids = length(rule.value.destination_ip_addresses) > 0 ? [vcd_nsxt_ip_set.this["${rule.value.name}-dst"].id] : null

      app_port_profile_ids = length(rule.value.app_port_profiles) + length(rule.value.custom_ports) > 0 ? concat(
        [for p in rule.value.app_port_profiles : data.vcd_nsxt_app_port_profile.system[p].id],
        length(rule.value.custom_ports) > 0 ? [vcd_nsxt_app_port_profile.custom[rule.value.name].id] : [],
      ) : null
    }
  }
}
