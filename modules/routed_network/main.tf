resource "vcd_network_routed_v2" "this" {
  org             = var.org
  name            = var.name
  description     = var.description
  edge_gateway_id = var.edge_gateway_id
  interface_type  = upper(var.interface_type)

  gateway       = var.gateway
  prefix_length = var.prefix_length

  dns1       = var.dns1
  dns2       = var.dns2
  dns_suffix = var.dns_suffix

  dynamic "static_ip_pool" {
    for_each = var.static_ip_pools
    content {
      start_address = static_ip_pool.value.start_address
      end_address   = static_ip_pool.value.end_address
    }
  }

  lifecycle {
    precondition {
      condition = !contains([
        cidrhost("${var.gateway}/${var.prefix_length}", 0),
        cidrhost("${var.gateway}/${var.prefix_length}", -1),
      ], var.gateway)
      error_message = "gateway ${var.gateway} is the network or broadcast address of its /${var.prefix_length} subnet; use a host address (e.g. ${cidrhost("${var.gateway}/${var.prefix_length}", 1)})."
    }
  }
}

# NSX-T DHCP is a separate resource attached to the network (EDGE mode)
resource "vcd_nsxt_network_dhcp" "this" {
  count = var.dhcp_pool != null ? 1 : 0

  org            = var.org
  org_network_id = vcd_network_routed_v2.this.id
  lease_time     = var.dhcp_pool.lease_time
  dns_servers    = compact([var.dns1, var.dns2])

  pool {
    start_address = var.dhcp_pool.start_address
    end_address   = var.dhcp_pool.end_address
  }
}
