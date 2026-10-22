output "dnat_ids" {
  value = { for k, r in vcd_nsxt_nat_rule.dnat : k => r.id }
}

output "snat_ids" {
  value = { for k, r in vcd_nsxt_nat_rule.snat : k => r.id }
}

output "ip_set_ids" {
  description = "Map of ip_sets key -> IP set ID (e.g. for firewall rules)"
  value       = { for k, s in vcd_nsxt_ip_set.this : k => s.id }
}
