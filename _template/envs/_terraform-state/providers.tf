# Lifecycle management of Microsoft Azure using the Azure Resource Manager APIs
# https://registry.terraform.io/providers/hashicorp/azurerm/latest
provider "azurerm" {
  storage_use_azuread = true

  features {}
}

# Used to interact with time-based resources. The provider itself has no configuration options.
# https://registry.terraform.io/providers/hashicorp/time/latest
provider "time" {}
