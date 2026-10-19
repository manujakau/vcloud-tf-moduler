# VMware Cloud Director Terraform Modules

This repository contains modular Terraform code for provisioning VMware Cloud Director resources (NSX-T networking) including:
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

### NSX-T networking

The networking modules target **NSX-T** backed Org VDCs. NSX-V resources
(`vcd_edgegateway`, `vcd_network_routed`, `vcd_nsxv_*`) are rejected by VCD for an
NSX-T backed VDC ("please use 'vcd_nsxt_edgegateway' for NSX-T backed VDC").

| Module           | Resources                                                                       |
|------------------|---------------------------------------------------------------------------------|
| `edge_gateway`   | `vcd_nsxt_edgegateway` (+ `vcd_external_network_v2` lookup by name)             |
| `routed_network` | `vcd_network_routed_v2`, `vcd_nsxt_network_dhcp` (when `dhcp_pool` is set)       |
| `firewall_rules` | `vcd_nsxt_firewall`, `vcd_nsxt_ip_set`, `vcd_nsxt_app_port_profile`             |
| `nat_rules`      | `vcd_nsxt_nat_rule`                                                              |

- The edge gateway uplinks to a Tier-0 backed external network. Its `primary_ip`
  must fall inside one of the subnet's `allocated_ips` ranges.
- `vcd_nsxt_firewall` owns the **whole ordered rule list** of the edge gateway. Do not
  manage firewall rules for the same gateway elsewhere. Traffic not matched by a rule
  hits the gateway's default deny rule. With `firewall_rules = []` no firewall
  resource is created.
- NSX-T rules reference objects, not raw values: the module creates one IP set per
  rule side (`<name>-src` / `<name>-dst`) and one tenant application port profile
  per rule with `custom_ports`. `app_port_profiles` take NSX-T built-in profile
  names such as `SSH`, `HTTP`, `HTTPS`, `ICMP ALL`.

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
- `vdc_network_pool_name`: Network pool name used by this VDC (NSX-T Geneve pool)
- `vdc_provider_vdc_name`: Provider VDC from which this organization VDC is provisioned
- `vdc_allocation_model`: Allocation model (ReservationPool, AllocationPool, etc.)
- `vdc_cpu_allocated`: CPU allocated to the VDC in MHz
- `vdc_memory_allocated`: Memory allocated to the VDC in MB
- `vdc_storage_profile`: Storage profile configuration for this VDC
- `vdc_network_quota`: Max networks in the VDC (default `10`). Unlike `vdc_nic_quota` /
  `vdc_vm_quota` where `0` means unlimited, `0` here means **no** networks can be created

### Edge Gateway Configuration
- `edge_gateway_name`: Name of the edge gateway
- `edge_gateway_description`: Description for the edge gateway
- `edge_gateway_external_network_name`: NSX-T Tier-0 backed external network name
- `edge_gateway_subnets`: Uplink subnets: `gateway`, `prefix_length`, `primary_ip`, `allocated_ips`
- `edge_gateway_dedicate_external_network`: Dedicate the Tier-0 to this gateway (default `false`)
- `edge_gateway_edge_cluster_id`: Specific NSX-T edge cluster (default: inherited)

### Network Configuration
- `routed_network_name`: Name of the routed network to create
- `routed_network_description`: Description for the routed network
- `routed_network_interface_type`: `INTERNAL` (default), `DISTRIBUTED`, `SUBINTERFACE`, `NON_DISTRIBUTED`
- `routed_network_gateway`: Gateway IP address for the network
- `routed_network_prefix_length`: Network prefix length (default `24`)
- `routed_network_dns1` / `routed_network_dns2` / `routed_network_dns_suffix`: DNS settings
- `routed_network_static_ip_pools`: Static IP pools for VMs
- `routed_network_dhcp_pool`: Optional edge DHCP pool (`start_address`, `end_address`, `lease_time`)

### Firewall Rules Configuration
- `firewall_rules`: Ordered list of rules. Each rule has `name` (unique), `action`
  (`ALLOW`/`DROP`/`REJECT`), `direction` (`IN`/`OUT`/`IN_OUT`), `ip_protocol`,
  `enabled`, `logging`, `source_ip_addresses`, `destination_ip_addresses`,
  `app_port_profiles` and `custom_ports`. Empty lists mean "any".

### NAT Rules Configuration
- `dnat_rules`: Map of DNAT rules: `external_address` → `internal_address`,
  optional `app_port_profile` (built-in name) and `dnat_external_port`
- `snat_rules`: Map of SNAT rules: `internal_address` (source) → `external_address`,
  optional `snat_destination_address`

## Example Usage

The root module wires all modules together; see [main.tf](main.tf) and
[terraform.tfvars.example](terraform.tfvars.example) for a complete set of inputs,
including firewall and NAT rule examples.

```hcl
module "edge_gateway" {
  source = "./modules/edge_gateway"

  org                   = module.org.org_name
  owner_id              = module.vdc.vdc_id
  name                  = "my-edge-gateway"
  external_network_name = "T0 External Network"

  subnets = [
    {
      gateway       = "192.168.30.49"
      prefix_length = 28
      primary_ip    = "192.168.30.51"
      allocated_ips = [{ start_address = "192.168.30.51", end_address = "192.168.30.52" }]
    }
  ]
}

module "routed_network" {
  source = "./modules/routed_network"

  org             = module.org.org_name
  name            = "my-network"
  edge_gateway_id = module.edge_gateway.gateway_id
  gateway         = "192.168.2.1"
  prefix_length   = 24

  dhcp_pool = {
    start_address = "192.168.2.100"
    end_address   = "192.168.2.200"
  }
}

module "firewall_rules" {
  source = "./modules/firewall_rules"

  org             = module.org.org_name
  vdc_id          = module.vdc.vdc_id
  edge_gateway_id = module.edge_gateway.gateway_id

  rules = [
    {
      name                     = "allow-ssh-in"
      direction                = "IN"
      destination_ip_addresses = ["192.168.2.0/24"]
      app_port_profiles        = ["SSH"]
    }
  ]
}

module "nat_rules" {
  source = "./modules/nat_rules"

  org             = module.org.org_name
  vdc_id          = module.vdc.vdc_id
  edge_gateway_id = module.edge_gateway.gateway_id

  dnat_rules = {
    web-dnat = {
      external_address = "192.168.30.52"
      internal_address = "192.168.2.10"
      app_port_profile = "HTTP"
    }
  }

  snat_rules = {
    outbound-snat = {
      internal_address = "192.168.2.0/24"
      external_address = "192.168.30.51"
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

