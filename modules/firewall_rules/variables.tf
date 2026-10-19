variable "org" {
  type = string
}

variable "vdc_id" {
  type        = string
  description = "Org VDC ID, used as context for application port profiles"
}

variable "edge_gateway_id" {
  type = string
}

# Ordered list: rules are evaluated top to bottom. Empty address/port lists mean "any".
variable "rules" {
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

  validation {
    condition     = length(distinct([for r in var.rules : r.name])) == length(var.rules)
    error_message = "Firewall rule names must be unique."
  }

  validation {
    condition = alltrue([for r in var.rules :
      contains(["ALLOW", "DROP", "REJECT"], r.action) &&
      contains(["IN", "OUT", "IN_OUT"], r.direction) &&
      contains(["IPV4", "IPV6", "IPV4_IPV6"], r.ip_protocol)
    ])
    error_message = "action must be ALLOW/DROP/REJECT, direction IN/OUT/IN_OUT, ip_protocol IPV4/IPV6/IPV4_IPV6."
  }
}
