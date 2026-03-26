variable "tags_additional" {
  description = "Tags adicionales opcionales"
  type        = map(string)
  default     = {}
}

variable "tags_mandatory" {
  description = "Tags obligatorios (CostCenter, Environment, Owner, etc.)"
  type        = map(string)
}

variable "location" {
  type = string
}

variable "vm_admin_password" {
  type        = string
  description = "Password for VM admin user"
}