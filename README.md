# VMware Cloud Director Terraform Modules

This repository contains modular Terraform code for provisioning VMware Cloud Director resources including:
- Organization
- Organization VDC (datacenter)
- Edge Gateway
- Routed Network
- Firewall Rules
- NAT Rules (DNAT/SNAT)

## Prerequisites

- Terraform 1.3 or higher
- VMware Cloud Director provider v3.14.2 or higher
- System administrator privileges for provisioning resources

## Notes

### NSX-V vs NSX-T Resources

This module set is designed for **NSX-V** backed networking (legacy). For NSX-T based environments, use the `vcd_network_routed_v2` resource instead.

### Advanced Networking Requirement

Firewall and NAT rules require an NSX-V edge gateway with Advanced Networking enabled
(mandatory since VCD 10.0). `edge_gateway_configuration` (compact, full, full4, x-large)
only sets the gateway size; every size supports firewall and NAT.

## Variables

### Provider Configuration
- `vcd_url`: VMware Cloud Director URL
- `vcd_username`: Username for authentication (system admin)
- `vcd_password`: Password for authentication

### Organization
- `org_name`: Name of organization to create
- `org_full_name`: Full name of organization
- `org_description`: Description of organization
- `org_is_enabled`: Whether organization is enabled

### VDC Configuration
- `vdc_name`: Name of the VDC to create
- `vdc_description`: Description for the VDC
- `vdc_network_pool_name`: Network pool name used by this VDC
- `vdc_provider_vdc_name`: Provider VDC from which this organization VDC is provisioned
- `vdc_allocation_model`: Allocation model (ReservationPool, AllocationPool, etc.)
- `vdc_cpu_allocated`: CPU allocated to the VDC in MHz
- `vdc_memory_allocated`: Memory allocated to the VDC in MB
- `vdc_storage_profile`: Storage profile configuration for this VDC

### Edge Gateway Configuration
- `edge_gateway_name`: Name of the edge gateway
- `edge_gateway_description`: Description for the edge gateway
- `edge_gateway_configuration`: Edge gateway configuration (compact, full, x-large, full4)
- `edge_gateway_external_network`: External network configuration with subnets and IP pools

### Network Configuration
- `routed_network_name`: Name of the routed network to create
- `routed_network_description`: Description for the routed network
- `routed_network_interface_type`: Interface type (internal, subinterface, distributed)
- `routed_network_gateway`: Gateway IP address for the network
- `routed_network_netmask`: Network netmask

### Firewall Rules Configuration
- `firewall_rules`: Map of firewall rules using rule names as keys

### NAT Rules Configuration
- `dnat_rules`: Map of DNAT rules to create (destination NAT)
- `snat_rules`: Map of SNAT rules to create (source NAT)

## Example Usage

```hcl
# Configure provider with environment variables or explicit values
provider "vcd" {
  url      = var.vcd_url
  user     = var.vcd_username
  password = var.vcd_password
  org      = "System"
}

# Create all resources using modules
module "org" {
  source = "./modules/org"
  
  name        = "my-org"
  full_name   = "My Organization"
  description = "Organization for my project"
  is_enabled  = true
}

module "vdc" {
  source = "./modules/vdc"
  
  org               = module.org.org_name
  name              = "my-vdc"
  description       = "Virtual Data Center for my project"
  network_pool_name = "MyNetworkPool"
  provider_vdc_name = "MyProviderVDC"
  
  allocation_model      = "ReservationPool"
  cpu_allocated         = 2048
  memory_allocated      = 2048
  enable_thin_provisioning = true
  enable_fast_provisioning = true
  
  storage_profile = [
    {
      name    = "*"
      limit   = 10240
      default = true
      enabled = true
    }
  ]
}

module "edge_gateway" {
  source = "./modules/edge_gateway"

  org         = module.org.org_name
  vdc         = module.vdc.vdc_name
  name        = "my-edge-gateway"
  description = "Edge gateway for my project"
  configuration = "full"

  external_networks = [
    {
      name = "MyExternalNetwork"
      subnets = [
        {
          gateway               = "192.168.30.49"
          netmask               = "255.255.255.240"
          ip_address            = "192.168.30.51"
          use_for_default_route = true
        }
      ]
    }
  ]

  ha_enabled       = false
  fw_enabled       = true
  lb_enabled       = false
}

module "routed_network" {
  source = "./modules/routed_network"

  org           = module.org.org_name
  vdc           = module.vdc.vdc_name
  name          = "my-network"
  description   = "Routed network for my project"
  edge_gateway  = module.edge_gateway.gateway_name
  interface_type = "internal"
  gateway       = "192.168.2.1"
  netmask       = "255.255.255.0"

  dhcp_pool = {
    start_address = "192.168.2.2"
    end_address   = "192.168.2.100"
    max_lease_time = 7200
  }
}

module "firewall_rules" {
  source = "./modules/firewall_rules"

  org           = module.org.org_name
  vdc           = module.vdc.vdc_name
  edge_gateway  = module.edge_gateway.gateway_name
  rules         = {
    allow-ssh = {
      action          = "accept"
      enabled         = true
      logging_enabled = false
      name            = "Allow SSH Access"
      
      source = {
        ip_addresses       = ["any"]
        gateway_interfaces = []
        org_networks       = []
        vm_ids             = []
        ip_sets            = []
      }
      
      destination = {
        ip_addresses       = ["any"]
        gateway_interfaces = []
        org_networks       = []
        vm_ids             = []
        ip_sets            = []
      }
      
      services = [
        {
          protocol     = "tcp"
          port         = "22"
          source_port  = "any"
        }
      ]
    }
  }
}

module "nat_rules" {
  source = "./modules/nat_rules"

  org          = module.org.org_name
  vdc          = module.vdc.vdc_name
  edge_gateway = module.edge_gateway.gateway_name

  dnat_rules = {
    web-dnat = {
      network_type   = "ext"
      network_name   = "MyExternalNetwork"
      original_address   = "1.1.1.10"
      translated_address = "192.168.2.10"
      protocol       = "tcp"
      original_port  = "80"
      translated_port = "80"
    }
  }

  snat_rules = {
    web-snat = {
      network_type   = "org"
      network_name   = "my-network"
      original_address   = "192.168.2.0/24"
      translated_address = "1.1.1.20"
    }
  }
}
```

## Terraform Commands

```bash
# Format Terraform files
terraform fmt -recursive

# Initialize Terraform (downloads provider and runs modules)
terraform init

# Validate configuration
terraform validate

# Apply the configuration
terraform apply
```

