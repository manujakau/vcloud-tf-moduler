output "network_id" {
  value = vcd_network_routed_v2.this.id
}

output "network_name" {
  value = vcd_network_routed_v2.this.name
}

output "network_gateway" {
  value = vcd_network_routed_v2.this.gateway
}
