variable "org" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "edge_gateway_id" {
  type = string
}

variable "interface_type" {
  type    = string
  default = "INTERNAL"
  validation {
    condition     = contains(["INTERNAL", "DISTRIBUTED", "SUBINTERFACE", "NON_DISTRIBUTED"], upper(var.interface_type))
    error_message = "interface_type must be one of: INTERNAL, DISTRIBUTED, SUBINTERFACE, NON_DISTRIBUTED"
  }
}

variable "gateway" {
  type = string
}

variable "prefix_length" {
  type    = number
  default = 24
}

variable "dns1" {
  type    = string
  default = null
}

variable "dns2" {
  type    = string
  default = null
}

variable "dns_suffix" {
  type    = string
  default = null
}

variable "static_ip_pools" {
  type = list(object({
    start_address = string
    end_address   = string
  }))
  default = []
}

variable "dhcp_pool" {
  type = object({
    start_address = string
    end_address   = string
    lease_time    = optional(number, 86400)
  })
  default = null
}
