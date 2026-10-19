output "rule_ids" {
  # Keyed from the input list so the keys are known at plan time
  value = { for i, r in var.rules : r.name => vcd_nsxt_firewall.this[0].rule[i].id }
}

output "ip_set_ids" {
  value = { for k, s in vcd_nsxt_ip_set.this : k => s.id }
}
