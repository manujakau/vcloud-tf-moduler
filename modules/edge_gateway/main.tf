# NSX-T edge gateway (Tier-1), uplinked to a Tier-0 backed external network
data "vcd_external_network_v2" "this" {
  name = var.external_network_name
}

resource "vcd_nsxt_edgegateway" "this" {
  org         = var.org
  owner_id    = var.owner_id
  name        = var.name
  description = var.description

  external_network_id       = data.vcd_external_network_v2.this.id
  dedicate_external_network = var.dedicate_external_network
  edge_cluster_id           = var.edge_cluster_id

  dynamic "subnet" {
    for_each = var.subnets
    content {
      gateway       = subnet.value.gateway
      prefix_length = subnet.value.prefix_length
      # Must fall inside one of the allocated_ips ranges below
      primary_ip = subnet.value.primary_ip

      dynamic "allocated_ips" {
        for_each = subnet.value.allocated_ips
        content {
          start_address = allocated_ips.value.start_address
          end_address   = allocated_ips.value.end_address
        }
      }
    }
  }
}
