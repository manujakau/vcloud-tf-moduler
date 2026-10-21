# Offline tests: the vcd provider is mocked, so no API calls are made.
#   cd modules/firewall_rules && terraform init -backend=false && terraform test

mock_provider "vcd" {}

variables {
  org             = "test-org"
  vdc_id          = "urn:vcloud:vdc:00000000-0000-0000-0000-000000000001"
  edge_gateway_id = "urn:vcloud:gateway:00000000-0000-0000-0000-000000000001"

  rules = [
    {
      name                     = "allow-ssh-in"
      direction                = "IN"
      destination_ip_addresses = ["10.10.1.0/24"]
      app_port_profiles        = ["SSH"]
    },
    {
      name                     = "allow-app-in"
      direction                = "IN"
      source_ip_addresses      = ["198.51.100.0/24"]
      destination_ip_addresses = ["10.10.1.10"]
      custom_ports             = [{ protocol = "tcp", ports = ["8080"] }]
    },
    {
      name                = "allow-out"
      direction           = "OUT"
      source_ip_addresses = ["10.10.1.0/24"]
    },
  ]
}

run "plan" {
  command = plan

  assert {
    condition     = toset(keys(vcd_nsxt_ip_set.this)) == toset(["allow-ssh-in-dst", "allow-app-in-src", "allow-app-in-dst", "allow-out-src"])
    error_message = "Expected one IP set per non-empty rule side"
  }

  assert {
    condition     = toset(keys(data.vcd_nsxt_app_port_profile.system)) == toset(["SSH"])
    error_message = "Expected one SYSTEM profile lookup per distinct app_port_profiles entry"
  }

  assert {
    condition     = keys(vcd_nsxt_app_port_profile.custom) == ["allow-app-in"]
    error_message = "Expected one custom profile per rule with custom_ports"
  }

  assert {
    condition     = one(vcd_nsxt_app_port_profile.custom["allow-app-in"].app_port).protocol == "TCP"
    error_message = "custom port protocol should be upper-cased"
  }

  assert {
    condition     = length(vcd_nsxt_firewall.this) == 1
    error_message = "Expected exactly one vcd_nsxt_firewall (it owns the whole rule list)"
  }

  assert {
    condition     = [for r in vcd_nsxt_firewall.this[0].rule : r.name] == ["allow-ssh-in", "allow-app-in", "allow-out"]
    error_message = "Rule order must follow the input list"
  }

  assert {
    condition     = vcd_nsxt_firewall.this[0].rule[0].action == "ALLOW" && vcd_nsxt_firewall.this[0].rule[0].ip_protocol == "IPV4"
    error_message = "action/ip_protocol defaults changed"
  }
}

run "apply_outputs" {
  command = apply

  assert {
    condition     = keys(output.rule_ids) == ["allow-app-in", "allow-out", "allow-ssh-in"]
    error_message = "rule_ids should be keyed by rule name"
  }

  assert {
    condition     = length(output.ip_set_ids) == 4
    error_message = "ip_set_ids should have one entry per IP set"
  }
}

run "empty_rules" {
  command = apply

  variables {
    rules = []
  }

  assert {
    condition     = length(vcd_nsxt_firewall.this) == 0
    error_message = "No firewall resource should be created for an empty rule list"
  }

  assert {
    condition     = output.rule_ids == {}
    error_message = "rule_ids should be empty"
  }
}

run "rejects_duplicate_names" {
  command = plan

  variables {
    rules = [{ name = "dup" }, { name = "dup" }]
  }

  expect_failures = [var.rules]
}

run "rejects_invalid_action" {
  command = plan

  variables {
    rules = [{ name = "bad", action = "PERMIT" }]
  }

  expect_failures = [var.rules]
}
