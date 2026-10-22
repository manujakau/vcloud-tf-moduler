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

# NAT addresses taken from named IP sets instead of raw values.
run "ip_set_mapping" {
  command = plan

  variables {
    ip_sets = {
      app-net = { ip_addresses = ["10.10.1.0/24"], description = "App network" }
      egw-ip  = { name = "edge-public-ip", ip_addresses = ["192.0.2.2"] }
      web-vm  = { ip_addresses = ["10.10.1.10"] }
      dns     = { ip_addresses = ["8.8.8.8"] }
      any     = { ip_addresses = ["0.0.0.0/0"] }
      multi   = { ip_addresses = ["10.10.1.0/24", "10.10.2.0/24"] } # firewall use only
    }
    dnat_rules = {
      web-dnat = { external_ip_set = "egw-ip", internal_ip_set = "web-vm", app_port_profile = "HTTP" }
    }
    snat_rules = {
      outbound = { internal_ip_set = "app-net", external_ip_set = "egw-ip", snat_destination_ip_set = "dns" }
      mixed    = { internal_ip_set = "app-net", external_address = "192.0.2.3" }
    }
  }

  assert {
    condition     = length(vcd_nsxt_ip_set.this) == 6
    error_message = "Expected one vcd_nsxt_ip_set per ip_sets entry"
  }

  assert {
    condition     = vcd_nsxt_ip_set.this["egw-ip"].name == "edge-public-ip" && vcd_nsxt_ip_set.this["app-net"].name == "app-net"
    error_message = "IP set name should be var name, defaulting to the map key"
  }

  assert {
    condition     = vcd_nsxt_nat_rule.dnat["web-dnat"].external_address == "192.0.2.2" && vcd_nsxt_nat_rule.dnat["web-dnat"].internal_address == "10.10.1.10"
    error_message = "DNAT addresses should come from the referenced IP sets"
  }

  assert {
    condition     = vcd_nsxt_nat_rule.snat["outbound"].internal_address == "10.10.1.0/24" && vcd_nsxt_nat_rule.snat["outbound"].external_address == "192.0.2.2"
    error_message = "SNAT addresses should come from the referenced IP sets"
  }

  assert {
    condition     = vcd_nsxt_nat_rule.snat["outbound"].snat_destination_address == "8.8.8.8"
    error_message = "snat_destination_address should come from snat_destination_ip_set"
  }

  assert {
    condition     = vcd_nsxt_nat_rule.snat["mixed"].internal_address == "10.10.1.0/24" && vcd_nsxt_nat_rule.snat["mixed"].external_address == "192.0.2.3"
    error_message = "A rule may mix an IP set reference and a raw address"
  }
}

run "ip_set_outputs" {
  command = apply

  variables {
    ip_sets = {
      app-net = { ip_addresses = ["10.10.1.0/24"] }
      egw-ip  = { ip_addresses = ["192.0.2.2"] }
    }
    dnat_rules = {}
    snat_rules = {
      outbound = { internal_ip_set = "app-net", external_ip_set = "egw-ip" }
    }
  }

  assert {
    condition     = keys(output.ip_set_ids) == ["app-net", "egw-ip"]
    error_message = "ip_set_ids should be keyed like var.ip_sets"
  }
}

run "rejects_address_and_ip_set_together" {
  command = plan

  variables {
    ip_sets    = { egw-ip = { ip_addresses = ["192.0.2.2"] } }
    dnat_rules = {}
    snat_rules = {
      bad = { internal_address = "10.10.1.0/24", external_address = "192.0.2.2", external_ip_set = "egw-ip" }
    }
  }

  expect_failures = [vcd_nsxt_nat_rule.snat]
}

run "rejects_missing_address" {
  command = plan

  variables {
    dnat_rules = {
      bad = { external_address = "192.0.2.3" }
    }
    snat_rules = {}
  }

  expect_failures = [vcd_nsxt_nat_rule.dnat]
}

run "rejects_unknown_ip_set" {
  command = plan

  variables {
    dnat_rules = {}
    snat_rules = {
      bad = { internal_ip_set = "does-not-exist", external_address = "192.0.2.2" }
    }
  }

  expect_failures = [vcd_nsxt_nat_rule.snat]
}

run "rejects_multi_address_ip_set" {
  command = plan

  variables {
    ip_sets    = { multi = { ip_addresses = ["10.10.1.0/24", "10.10.2.0/24"] } }
    dnat_rules = {}
    snat_rules = {
      bad = { internal_ip_set = "multi", external_address = "192.0.2.2" }
    }
  }

  expect_failures = [vcd_nsxt_nat_rule.snat]
}

run "rejects_duplicate_ip_set_names" {
  command = plan

  variables {
    ip_sets = {
      a = { name = "same", ip_addresses = ["10.10.1.0/24"] }
      b = { name = "same", ip_addresses = ["10.10.2.0/24"] }
    }
  }

  expect_failures = [var.ip_sets]
}
