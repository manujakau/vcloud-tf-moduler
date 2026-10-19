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

variable "provider_vdc_name" {
  type = string
}

variable "allocation_model" {
  type = string
}

variable "network_pool_name" {
  type = string
}

variable "cpu_allocated" {
  type = number
}

variable "memory_allocated" {
  type = number
}

variable "storage_profile" {
  type = list(object({
    name    = string
    limit   = number
    default = bool
    enabled = bool
  }))
}

variable "enable_thin_provisioning" {
  type    = bool
  default = false
}

variable "enable_fast_provisioning" {
  type    = bool
  default = false
}

variable "nic_quota" {
  type    = number
  default = 0
}

variable "network_quota" {
  type        = number
  description = "Max networks in the VDC. Unlike nic/vm quotas, 0 means none can be created (not unlimited)."
  default     = 10
}

variable "vm_quota" {
  type    = number
  default = 0
}


variable "memory_guaranteed" {
  type    = number
  default = null
}

variable "cpu_guaranteed" {
  type    = number
  default = null
}

variable "enabled" {
  type    = bool
  default = true
}

variable "delete_force" {
  type    = bool
  default = false
}

variable "delete_recursive" {
  type    = bool
  default = false
}