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
