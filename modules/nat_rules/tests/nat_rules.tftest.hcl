# Offline tests: the vcd provider is mocked, so no API calls are made.
#   cd modules/nat_rules && terraform init -backend=false && terraform test

mock_provider "vcd" {}

variables {
  org             = "test-org"
  vdc_id          = "urn:vcloud:vdc:00000000-0000-0000-0000-000000000001"
  edge_gateway_id = "urn:vcloud:gateway:00000000-0000-0000-0000-000000000001"

  dnat_rules = {
    web-dnat = {
      external_address   = "192.0.2.3"
      internal_address   = "10.10.1.10"
      app_port_profile   = "HTTP"
      dnat_external_port = "8080"
    }
  }

  snat_rules = {
    outbound-snat = {
      internal_address = "10.10.1.0/24"
      external_address = "192.0.2.2"
    }
    named-snat = {
      name             = "custom-name"
      internal_address = "10.10.2.0/24"
      external_address = "192.0.2.2"
      enabled          = false
    }
  }
}

run "plan" {
  command = plan

  assert {
    condition     = vcd_nsxt_nat_rule.dnat["web-dnat"].rule_type == "DNAT" && vcd_nsxt_nat_rule.dnat["web-dnat"].name == "web-dnat"
    error_message = "DNAT rule should use rule_type DNAT and default its name to the map key"
  }

  assert {
    condition     = vcd_nsxt_nat_rule.dnat["web-dnat"].dnat_external_port == "8080"
    error_message = "dnat_external_port not passed through"
  }

  assert {
    condition     = toset(keys(data.vcd_nsxt_app_port_profile.system)) == toset(["HTTP"])
    error_message = "Expected one SYSTEM profile lookup per distinct app_port_profile"
  }

  assert {
    condition     = vcd_nsxt_nat_rule.snat["outbound-snat"].rule_type == "SNAT" && vcd_nsxt_nat_rule.snat["outbound-snat"].name == "outbound-snat"
    error_message = "SNAT rule should use rule_type SNAT and default its name to the map key"
  }

  assert {
    condition     = vcd_nsxt_nat_rule.snat["named-snat"].name == "custom-name" && vcd_nsxt_nat_rule.snat["named-snat"].enabled == false
    error_message = "Explicit name/enabled not passed through"
  }
}

run "apply_outputs" {
  command = apply

  assert {
    condition     = keys(output.dnat_ids) == ["web-dnat"] && keys(output.snat_ids) == ["named-snat", "outbound-snat"]
    error_message = "Output maps should be keyed like the input maps"
  }
}

run "no_rules" {
  command = plan

  variables {
    dnat_rules = {}
    snat_rules = {}
  }

  assert {
    condition     = length(vcd_nsxt_nat_rule.dnat) == 0 && length(vcd_nsxt_nat_rule.snat) == 0 && length(data.vcd_nsxt_app_port_profile.system) == 0
    error_message = "No NAT rules or lookups should be planned for empty inputs"
  }
}
