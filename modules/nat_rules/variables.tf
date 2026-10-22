variable "org" {
  type = string
}

variable "vdc_id" {
  type        = string
  description = "Org VDC ID, used as context for application port profile lookups"
}

variable "edge_gateway_id" {
  type = string
}

# Named IP sets on the edge gateway. NAT rules can reference a set by key
# instead of a raw address; such a set must contain exactly one IP or CIDR.
variable "ip_sets" {
  type = map(object({
    name         = optional(string) # defaults to the map key
    description  = optional(string)
    ip_addresses = list(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.ip_sets : length(s.ip_addresses) > 0])
    error_message = "Every IP set needs at least one entry in ip_addresses."
  }

  validation {
    condition     = length(distinct([for k, s in var.ip_sets : coalesce(s.name, k)])) == length(var.ip_sets)
    error_message = "IP set names (name, or the map key when name is unset) must be unique."
  }
}

# For each address, set either the raw value (*_address) or an IP set key (*_ip_set), not both.
variable "dnat_rules" {
  type = map(object({
    name               = optional(string)
    description        = optional(string)
    enabled            = optional(bool, true)
    logging            = optional(bool, false)
    external_address   = optional(string)
    external_ip_set    = optional(string)
    internal_address   = optional(string)
    internal_ip_set    = optional(string)
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
    external_address         = optional(string)
    external_ip_set          = optional(string)
    internal_address         = optional(string)
    internal_ip_set          = optional(string)
    snat_destination_address = optional(string)
    snat_destination_ip_set  = optional(string)
    firewall_match           = optional(string)
    priority                 = optional(number)
  }))
  default = {}
}
