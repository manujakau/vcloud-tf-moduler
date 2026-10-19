output "dnat_ids" {
  value = { for k, r in vcd_nsxt_nat_rule.dnat : k => r.id }
}

output "snat_ids" {
  value = { for k, r in vcd_nsxt_nat_rule.snat : k => r.id }
}
