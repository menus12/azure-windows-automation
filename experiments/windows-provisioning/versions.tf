terraform {
  required_version = ">= 1.9"

  # Partial configuration: storage account, container and state key come
  # from a *.azurerm.tfbackend file. See docs/runbooks/vdi-setup.md.
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
