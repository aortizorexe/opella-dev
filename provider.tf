terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstateopella001"
    container_name       = "tfstate"
    key                  = "opella-dev.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = "5a585ebb-cc4d-4a0f-8a96-1983a7047c98"
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}