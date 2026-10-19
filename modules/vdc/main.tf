resource "vcd_org_vdc" "this" {
  org         = var.org
  name        = var.name
  description = var.description

  provider_vdc_name = var.provider_vdc_name
  allocation_model  = var.allocation_model
  network_pool_name = var.network_pool_name

  compute_capacity {
    cpu {
      allocated = var.cpu_allocated
    }

    memory {
      allocated = var.memory_allocated
    }
  }

  dynamic "storage_profile" {
    for_each = var.storage_profile
    content {
      name    = storage_profile.value.name
      limit   = storage_profile.value.limit
      default = storage_profile.value.default
      enabled = storage_profile.value.enabled
    }
  }

  # VDC settings
  enable_thin_provisioning = var.enable_thin_provisioning
  enable_fast_provisioning = var.enable_fast_provisioning

  nic_quota     = var.nic_quota
  network_quota = var.network_quota
  vm_quota      = var.vm_quota

  # Optional settings (only for AllocationVApp, AllocationPool, Flex)
  memory_guaranteed = var.memory_guaranteed
  cpu_guaranteed    = var.cpu_guaranteed

  # Optional settings
  enabled          = var.enabled
  delete_force     = var.delete_force
  delete_recursive = var.delete_recursive
}