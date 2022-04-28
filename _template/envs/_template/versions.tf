terraform {
  required_version = "~> 1"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}
