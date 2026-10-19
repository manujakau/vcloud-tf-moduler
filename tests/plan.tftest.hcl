# Offline plan: the vcd provider is mocked, so no API calls are made.
# Inputs come from terraform.tfvars in the root module (or pass -var-file).
#
#   terraform test            # pass/fail
#   terraform test -verbose   # also prints the full plan

mock_provider "vcd" {}

run "plan" {
  command = plan

  assert {
    condition     = module.org.org_name == var.org_name
    error_message = "Org name does not match var.org_name"
  }

  assert {
    condition     = length(module.firewall_rules.rule_ids) == length(var.firewall_rules)
    error_message = "Firewall rule count does not match var.firewall_rules"
  }

  assert {
    condition     = length(module.nat_rules.dnat_ids) == length(var.dnat_rules) && length(module.nat_rules.snat_ids) == length(var.snat_rules)
    error_message = "NAT rule count does not match var.dnat_rules / var.snat_rules"
  }
}
