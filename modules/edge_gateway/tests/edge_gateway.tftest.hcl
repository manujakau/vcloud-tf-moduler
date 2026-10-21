# Offline tests: the vcd provider is mocked, so no API calls are made.
#   cd modules/edge_gateway && terraform init -backend=false && terraform test

mock_provider "vcd" {
  mock_data "vcd_external_network_v2" {
    defaults = {
      id = "urn:vcloud:network:00000000-0000-0000-0000-0000000000e1"
    }
  }
}

variables {
  org                   = "test-org"
  owner_id              = "urn:vcloud:vdc:00000000-0000-0000-0000-000000000001"
  name                  = "test-egw"
  external_network_name = "T0 External Network"

  subnets = [
    {
      gateway       = "192.0.2.1"
      prefix_length = 28
      primary_ip    = "192.0.2.2"
      allocated_ips = [{ start_address = "192.0.2.2", end_address = "192.0.2.3" }]
    }
  ]
}

run "plan" {
  command = plan

  assert {
    condition     = vcd_nsxt_edgegateway.this.owner_id == var.owner_id
    error_message = "owner_id not passed through"
  }

  assert {
    condition     = vcd_nsxt_edgegateway.this.external_network_id == "urn:vcloud:network:00000000-0000-0000-0000-0000000000e1"
    error_message = "external_network_id should come from the vcd_external_network_v2 lookup"
  }

  assert {
    condition     = length(vcd_nsxt_edgegateway.this.subnet) == 1
    error_message = "Expected one subnet block per input entry"
  }

  assert {
    condition     = vcd_nsxt_edgegateway.this.dedicate_external_network == false
    error_message = "dedicate_external_network should default to false"
  }
}

run "apply_outputs" {
  command = apply

  assert {
    condition     = output.gateway_name == "test-egw"
    error_message = "gateway_name output does not match var.name"
  }

  assert {
    condition     = output.gateway_id != null && output.gateway_id != ""
    error_message = "gateway_id output is empty"
  }
}
