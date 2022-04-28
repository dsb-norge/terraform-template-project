# Instruct terraform to use azurerm as backend for state
# See https://www.terraform.io/docs/backends/index.html for more information.

# NOTE:
#   The actual configuration of the azurerm backend for each environment
#   recides in the 'backend-config.ENV.hcl' files.
terraform {
  backend "azurerm" {}
}
