variable "subscription_id" {
  description = "Azure subscription to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
  default     = "awa-poc-scriptfail"
}

variable "vm_size" {
  description = "VM size."
  type        = string
  default     = "Standard_B2s"
}
