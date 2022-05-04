# This configures terraform to use azurerm as backend.
# See https://www.terraform.io/docs/backends/index.html for more information.
#
# NOTE:
#   The actual Azure resources for the remote state are managed in envs/_terraform-state
terraform {
  backend "azurerm" {
    resource_group_name  = "[BOOTSTRAP_VALUE_RG_NAME]"
    storage_account_name = "[BOOTSTRAP_VALUE_STRG_ACC_NAME]"
    container_name       = "[BOOTSTRAP_VALUE_STATE_NAME]"
    key                  = "env.[BOOTSTRAP_VALUE_ENV_NAME]"
  }
}
