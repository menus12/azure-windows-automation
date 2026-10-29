terraform {
  required_version = ">= 1.9"

  # Partial configuration: storage account and container come from a
  # *.azurerm.tfbackend file, the state key from -backend-config on init.
  # See docs/runbooks/vdi-setup.md.
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
