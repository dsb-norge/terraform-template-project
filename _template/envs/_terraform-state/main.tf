provider "azurerm" {
  features {}
}
module "terraform_state_container" {
  source = "git@github.com:dsb-norge/tf-mod-azure-terraform-state-container.git?ref=v1"

  subscription_number              = var.subscription_number
  application_name                 = var.application_name
  application_name_short           = var.application_name_short
  application_friendly_description = var.application_friendly_description
  environment_name                 = var.environment_name
  created_by_tag                   = var.created_by_tag
}
