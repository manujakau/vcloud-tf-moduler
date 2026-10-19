# Provider variables
variable "vcd_url" {
  type        = string
  description = "URL of the vCloud Director instance"
  default     = null
}

variable "vcd_username" {
  type        = string
  description = "Username for vCloud Director access"
  default     = null
}

variable "vcd_password" {
  type        = string
  description = "Password for vCloud Director access"
  default     = null
  sensitive   = true
}

# Organization variables
variable "org_name" {
  type        = string
  description = "Name of the organization to create"
}

variable "org_full_name" {
  type = string
}

variable "org_description" {
  type    = string
  default = null
}

variable "org_is_enabled" {
  type    = bool
  default = true
}

# VDC variables
variable "vdc_name" {
  type = string
}

variable "vdc_description" {
  type    = string
  default = null
}

variable "vdc_network_pool_name" {
  type = string
}

variable "vdc_provider_vdc_name" {
  type = string
}

variable "vdc_allocation_model" {
  type = string
  validation {
    condition     = contains(["AllocationVApp", "AllocationPool", "ReservationPool", "Flex"], var.vdc_allocation_model)
    error_message = "allocation_model must be one of: AllocationVApp, AllocationPool, ReservationPool, Flex"
  }
}

variable "vdc_cpu_allocated" {
  type = number
}

variable "vdc_memory_allocated" {
  type = number
}

variable "vdc_storage_profile" {
  type = list(object({
    name    = string
    limit   = number
    default = optional(bool, true)
    enabled = optional(bool, true)
  }))
}

variable "vdc_enable_thin_provisioning" {
  type    = bool
  default = false
}

variable "vdc_enable_fast_provisioning" {
  type    = bool
  default = false
}

variable "vdc_nic_quota" {
  type    = number
  default = 0
}

variable "vdc_network_quota" {
  type        = number
  description = "Max networks in the VDC. Unlike nic/vm quotas, 0 means none can be created (not unlimited)."
  default     = 10
}

variable "vdc_vm_quota" {
  type    = number
  default = 0
}

# VDC optional variables
variable "vdc_memory_guaranteed" {
  type    = number
  default = null
}

variable "vdc_cpu_guaranteed" {
  type    = number
  default = null
}

variable "vdc_enabled" {
  type    = bool
  default = true
}

variable "vdc_delete_force" {
  type    = bool
  default = true
}

variable "vdc_delete_recursive" {
  type    = bool
  default = true
}

# Edge Gateway variables (NSX-T)
variable "edge_gateway_name" {
  type = string
}

variable "edge_gateway_description" {
  type    = string
  default = null
}

variable "edge_gateway_external_network_name" {
  type        = string
  description = "Name of the NSX-T Tier-0 backed external network to uplink to"
}

variable "edge_gateway_subnets" {
  type = list(object({
    gateway       = string
    prefix_length = number
    primary_ip    = optional(string)
    allocated_ips = list(object({
      start_address = string
      end_address   = string
    }))
  }))
  description = "External network subnets and IPs allocated to the edge gateway. primary_ip must be inside allocated_ips."
}

variable "edge_gateway_dedicate_external_network" {
  type    = bool
  default = false
}

variable "edge_gateway_edge_cluster_id" {
  type        = string
  description = "NSX-T edge cluster ID; inherited from the external network when null"
  default     = null
}

# Routed Network variables (NSX-T)
variable "routed_network_name" {
  type = string
}

variable "routed_network_description" {
  type    = string
  default = null
}

variable "routed_network_interface_type" {
  type    = string
  default = "INTERNAL"
}

variable "routed_network_gateway" {
  type = string
}

variable "routed_network_prefix_length" {
  type    = number
  default = 24
}

variable "routed_network_dns1" {
  type    = string
  default = null
}

variable "routed_network_dns2" {
  type    = string
  default = null
}

variable "routed_network_dns_suffix" {
  type    = string
  default = null
}

variable "routed_network_static_ip_pools" {
  type = list(object({
    start_address = string
    end_address   = string
  }))
  default = []
}

variable "routed_network_dhcp_pool" {
  type = object({
    start_address = string
    end_address   = string
    lease_time    = optional(number, 86400)
  })
  default = null
}

# Firewall Rules variables (ordered; evaluated top to bottom)
variable "firewall_rules" {
  type = list(object({
    name                     = string
    action                   = optional(string, "ALLOW")
    direction                = optional(string, "IN_OUT")
    ip_protocol              = optional(string, "IPV4")
    enabled                  = optional(bool, true)
    logging                  = optional(bool, false)
    source_ip_addresses      = optional(list(string), [])
    destination_ip_addresses = optional(list(string), [])
    app_port_profiles        = optional(list(string), [])
    custom_ports = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
  }))
  default = []
}

# NAT Rules variables
variable "dnat_rules" {
  type = map(object({
    name               = optional(string)
    description        = optional(string)
    enabled            = optional(bool, true)
    logging            = optional(bool, false)
    external_address   = string
    internal_address   = string
    dnat_external_port = optional(string)
    app_port_profile   = optional(string)
    firewall_match     = optional(string)
    priority           = optional(number)
  }))
  default = {}
}

variable "snat_rules" {
  type = map(object({
    name                     = optional(string)
    description              = optional(string)
    enabled                  = optional(bool, true)
    logging                  = optional(bool, false)
    external_address         = string
    internal_address         = string
    snat_destination_address = optional(string)
    firewall_match           = optional(string)
    priority                 = optional(number)
  }))
  default = {}
}
