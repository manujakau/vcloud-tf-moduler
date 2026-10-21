# Offline tests: the vcd provider is mocked, so no API calls are made.
#   cd modules/org && terraform init -backend=false && terraform test

mock_provider "vcd" {}

variables {
  name = "test-org"
}

run "defaults" {
  command = plan

  assert {
    condition     = vcd_org.this.name == "test-org"
    error_message = "Org name does not match var.name"
  }

  # vcd_org.full_name is required by the provider, but the module defaults it
  # to "". Callers (e.g. the Terragrunt org unit) must always set it.
  assert {
    condition     = vcd_org.this.full_name == ""
    error_message = "full_name module default changed; update callers and README"
  }

  assert {
    condition     = vcd_org.this.is_enabled == true
    error_message = "Org should be enabled by default"
  }

  assert {
    condition     = output.org_name == "test-org"
    error_message = "org_name output does not match var.name"
  }
}

run "explicit_inputs" {
  command = plan

  variables {
    full_name   = "Test Organization"
    description = "managed by terraform test"
    is_enabled  = false
  }

  assert {
    condition     = vcd_org.this.full_name == "Test Organization"
    error_message = "full_name not passed through"
  }

  assert {
    condition     = vcd_org.this.description == "managed by terraform test"
    error_message = "description not passed through"
  }

  assert {
    condition     = vcd_org.this.is_enabled == false
    error_message = "is_enabled not passed through"
  }
}

run "apply_outputs" {
  command = apply

  assert {
    condition     = output.org_id != null && output.org_id != ""
    error_message = "org_id output is empty"
  }
}
