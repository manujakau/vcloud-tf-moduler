# Offline tests: the vcd provider is mocked, so no API calls are made.
#   cd modules/routed_network && terraform init -backend=false && terraform test

mock_provider "vcd" {}

variables {
  org             = "test-org"
  name            = "app-net"
  edge_gateway_id = "urn:vcloud:gateway:00000000-0000-0000-0000-000000000001"
  gateway         = "10.10.1.1"
  prefix_length   = 24
}

run "no_dhcp" {
  command = plan

  assert {
    condition     = vcd_network_routed_v2.this.interface_type == "INTERNAL"
    error_message = "interface_type should default to INTERNAL"
  }

  assert {
    condition     = length(vcd_nsxt_network_dhcp.this) == 0
    error_message = "DHCP should not be created when dhcp_pool is null"
  }
}

run "with_dhcp_and_pools" {
  command = plan

  variables {
    interface_type  = "distributed"
    dns1            = "10.10.1.53"
    static_ip_pools = [{ start_address = "10.10.1.10", end_address = "10.10.1.99" }]
    dhcp_pool       = { start_address = "10.10.1.100", end_address = "10.10.1.200" }
  }

  assert {
    condition     = vcd_network_routed_v2.this.interface_type == "DISTRIBUTED"
    error_message = "interface_type should be upper-cased"
  }

  assert {
    condition     = length(vcd_network_routed_v2.this.static_ip_pool) == 1
    error_message = "Expected one static_ip_pool block per input entry"
  }

  assert {
    condition     = length(vcd_nsxt_network_dhcp.this) == 1
    error_message = "DHCP should be created when dhcp_pool is set"
  }

  assert {
    condition     = vcd_nsxt_network_dhcp.this[0].lease_time == 86400
    error_message = "lease_time should default to 86400"
  }

  assert {
    condition     = vcd_nsxt_network_dhcp.this[0].dns_servers == tolist(["10.10.1.53"])
    error_message = "dns_servers should be compact([dns1, dns2])"
  }
}

run "rejects_network_address_as_gateway" {
  command = plan

  variables {
    gateway = "10.10.1.0"
  }

  expect_failures = [vcd_network_routed_v2.this]
}

run "rejects_invalid_interface_type" {
  command = plan

  variables {
    interface_type = "BRIDGED"
  }

  expect_failures = [var.interface_type]
}
