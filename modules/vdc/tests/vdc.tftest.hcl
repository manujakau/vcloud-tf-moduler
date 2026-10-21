# Offline tests: the vcd provider is mocked, so no API calls are made.
#   cd modules/vdc && terraform init -backend=false && terraform test

mock_provider "vcd" {}

variables {
  org               = "test-org"
  name              = "test-vdc"
  provider_vdc_name = "test-pvdc"
  network_pool_name = "test-geneve-pool"
  allocation_model  = "Flex"
  cpu_allocated     = 2000
  memory_allocated  = 4096

  # default/enabled have no defaults in this module (they were optional at the
  # old root), so callers must always set them.
  storage_profile = [
    { name = "gold", limit = 102400, default = true, enabled = true },
    { name = "silver", limit = 51200, default = false, enabled = true },
  ]
}

run "defaults" {
  command = plan

  assert {
    condition     = vcd_org_vdc.this.org == "test-org" && vcd_org_vdc.this.name == "test-vdc"
    error_message = "org/name not passed through"
  }

  assert {
    condition     = vcd_org_vdc.this.compute_capacity[0].cpu[0].allocated == 2000 && vcd_org_vdc.this.compute_capacity[0].memory[0].allocated == 4096
    error_message = "compute_capacity not passed through"
  }

  assert {
    condition     = vcd_org_vdc.this.network_quota == 10
    error_message = "network_quota default should be 10 (0 means no networks)"
  }

  # Module defaults are false; the old root module defaulted both to true.
  assert {
    condition     = vcd_org_vdc.this.delete_force == false && vcd_org_vdc.this.delete_recursive == false
    error_message = "delete_force/delete_recursive module defaults changed"
  }
}

run "delete_flags_passthrough" {
  command = plan

  variables {
    delete_force     = true
    delete_recursive = true
  }

  assert {
    condition     = vcd_org_vdc.this.delete_force == true && vcd_org_vdc.this.delete_recursive == true
    error_message = "delete_force/delete_recursive not passed through"
  }
}

run "apply_outputs" {
  command = apply

  # storage_profile is a set with computed attributes, so its length is only
  # known after apply.
  assert {
    condition     = length(vcd_org_vdc.this.storage_profile) == 2
    error_message = "Expected one storage_profile block per input entry"
  }

  assert {
    condition     = output.vdc_name == "test-vdc"
    error_message = "vdc_name output does not match var.name"
  }

  assert {
    condition     = output.vdc_id != null && output.vdc_id != ""
    error_message = "vdc_id output is empty"
  }
}
