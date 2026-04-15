# This configures terraform to use azurerm as backend.
# See https://www.terraform.io/docs/backends/index.html for more information.
#
# NOTE:
#   The actual Azure resources for the remote state are managed externally.
#   TODO: Update the values below to point to the pre-provisioned state container.
terraform {
  backend "azurerm" {
    subscription_id      = "TODO" # subscription ID where the state container resides
    tenant_id            = "TODO" # Azure AD tenant ID
    resource_group_name  = "TODO"
    storage_account_name = "TODO"
    container_name       = "TODO"
    key                  = "env.[BOOTSTRAP_VALUE_ENV_NAME]"
    use_azuread_auth     = true
  }
}
