variable "org" {
  type = string
}

variable "owner_id" {
  type        = string
  description = "ID of the Org VDC (or VDC Group) that owns the edge gateway"
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "external_network_name" {
  type        = string
  description = "Name of the NSX-T Tier-0 backed external network"
}

variable "subnets" {
  type = list(object({
    gateway       = string
    prefix_length = number
    primary_ip    = optional(string)
    allocated_ips = list(object({
      start_address = string
      end_address   = string
    }))
  }))
}

variable "dedicate_external_network" {
  type    = bool
  default = false
}

variable "edge_cluster_id" {
  type    = string
  default = null
}
