output "org_id" {
  value = module.org.org_id
}

output "vdc_id" {
  value = module.vdc.vdc_id
}

output "gateway_id" {
  value = module.edge_gateway.gateway_id
}

output "network_id" {
  value = module.routed_network.network_id
}

output "firewall_rule_ids" {
  value = module.firewall_rules.rule_ids
}

output "dnat_rule_ids" {
  value = module.nat_rules.dnat_ids
}

output "snat_rule_ids" {
  value = module.nat_rules.snat_ids
}

output "nat_ip_set_ids" {
  value = module.nat_rules.ip_set_ids
}