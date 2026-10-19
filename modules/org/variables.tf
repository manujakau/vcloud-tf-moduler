variable "name" {
  description = "Name of the vCloud Director organization."
  type        = string
}

variable "full_name" {
  description = "Full (display) name of the organization."
  type        = string

  default = ""
}

variable "description" {
  description = "Description of the organization."
  type        = string

  default = ""
}

variable "is_enabled" {
  description = "Whether the organization is enabled."
  type        = bool

  default = true
}
