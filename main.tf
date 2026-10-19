terraform {
  backend "local" {}
}

provider "vcd" {
  # Prefer VCD_URL / VCD_USERNAME / VCD_PASSWORD environment variables.
  # Explicit values below override the environment.
  url      = var.vcd_url
  user     = var.vcd_username
  password = var.vcd_password
  org      = "System"
}

# All resources in this stack require System Admin privileges.

# ---------------------------------------------------------------------------
# Organization
# ---------------------------------------------------------------------------
module "org" {
  source = "./modules/org"

  name        = var.org_name
  full_name   = var.org_full_name
  description = var.org_description
  is_enabled  = var.org_is_enabled
}

# ---------------------------------------------------------------------------
# Organization VDC (datacenter)
# ---------------------------------------------------------------------------
module "vdc" {
  source = "./modules/vdc"

  org               = module.org.org_name
  name              = var.vdc_name
  description       = var.vdc_description
  network_pool_name = var.vdc_network_pool_name
  provider_vdc_name = var.vdc_provider_vdc_name

  allocation_model         = var.vdc_allocation_model
  cpu_allocated            = var.vdc_cpu_allocated
  memory_allocated         = var.vdc_memory_allocated
  nic_quota                = var.vdc_nic_quota
  network_quota            = var.vdc_network_quota
  vm_quota                 = var.vdc_vm_quota
  storage_profile          = var.vdc_storage_profile
  enable_thin_provisioning = var.vdc_enable_thin_provisioning
  enable_fast_provisioning = var.vdc_enable_fast_provisioning
  memory_guaranteed        = var.vdc_memory_guaranteed
  cpu_guaranteed           = var.vdc_cpu_guaranteed
  enabled                  = var.vdc_enabled
  delete_force             = var.vdc_delete_force
  delete_recursive         = var.vdc_delete_recursive
}

# ---------------------------------------------------------------------------
# Edge Gateway (NSX-T)
# ---------------------------------------------------------------------------
module "edge_gateway" {
  source = "./modules/edge_gateway"

  org         = module.org.org_name
  owner_id    = module.vdc.vdc_id
  name        = var.edge_gateway_name
  description = var.edge_gateway_description

  external_network_name     = var.edge_gateway_external_network_name
  subnets                   = var.edge_gateway_subnets
  dedicate_external_network = var.edge_gateway_dedicate_external_network
  edge_cluster_id           = var.edge_gateway_edge_cluster_id
}

# ---------------------------------------------------------------------------
# Routed Network (NSX-T)
# ---------------------------------------------------------------------------
module "routed_network" {
  source = "./modules/routed_network"

  org             = module.org.org_name
  name            = var.routed_network_name
  description     = var.routed_network_description
  edge_gateway_id = module.edge_gateway.gateway_id
  interface_type  = var.routed_network_interface_type
  gateway         = var.routed_network_gateway
  prefix_length   = var.routed_network_prefix_length
  dns1            = var.routed_network_dns1
  dns2            = var.routed_network_dns2
  dns_suffix      = var.routed_network_dns_suffix
  static_ip_pools = var.routed_network_static_ip_pools
  dhcp_pool       = var.routed_network_dhcp_pool
}

# ---------------------------------------------------------------------------
# Firewall Rules (NSX-T edge gateway)
# ---------------------------------------------------------------------------
module "firewall_rules" {
  source = "./modules/firewall_rules"

  org             = module.org.org_name
  vdc_id          = module.vdc.vdc_id
  edge_gateway_id = module.edge_gateway.gateway_id
  rules           = var.firewall_rules
}

# ---------------------------------------------------------------------------
# NAT Rules - DNAT + SNAT (NSX-T edge gateway)
# ---------------------------------------------------------------------------
module "nat_rules" {
  source = "./modules/nat_rules"

  org             = module.org.org_name
  vdc_id          = module.vdc.vdc_id
  edge_gateway_id = module.edge_gateway.gateway_id

  dnat_rules = var.dnat_rules
  snat_rules = var.snat_rules
}
