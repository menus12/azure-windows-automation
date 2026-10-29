variable "subscription_id" {
  description = "Azure subscription to deploy into. Defaults to ARM_SUBSCRIPTION_ID."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
  default     = "awa-poc-cfgtest"
}

variable "vm_size" {
  description = "VM size."
  type        = string
  default     = "Standard_B2s"
}

variable "disk_controller_type" {
  description = "OS disk controller: SCSI or NVMe. v6 and newer sizes (e.g. Dsv7) support NVMe only. Null keeps the Azure default (SCSI)."
  type        = string
  default     = null
}

variable "image" {
  description = "Marketplace image reference."
  type = object({
    publisher = string
    offer     = string
    sku       = string
  })
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-smalldisk-g2"
  }
}

variable "license_type" {
  description = "Licensing benefit: Windows_Client for Windows 10/11 images, null for Windows Server pay-as-you-go."
  type        = string
  default     = null
}

variable "trusted_launch" {
  description = "Enable Secure Boot and vTPM (Trusted Launch). Expected by Windows 11."
  type        = bool
  default     = false
}
