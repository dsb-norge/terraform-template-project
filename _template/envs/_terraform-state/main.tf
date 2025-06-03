data "azurerm_client_config" "current" {}

locals {
  network_rules = {
    default_action = "Deny"
    bypass         = null
    ip_rules = [
      "91.229.21.0/24", # CIDR mask for DSB public IP addresses.
      # TODO: add more here, like Azure FW outbound
    ]
    virtual_network_subnet_ids = null

    # Defender for Cloud Storage Data Scanner
    private_link_access = {
      endpoint_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Security/datascanners/storageDataScanner"
      endpoint_tenant_id   = data.azurerm_client_config.current.tenant_id
    }
  }
}

module "terraform_state_container" {
  source  = "dsb-norge/terraform-state-container/azurerm"
  version = "2.1.0"

  subscription_number              = var.subscription_number
  application_name                 = var.application_name
  application_name_short           = var.application_name_short
  application_friendly_description = var.application_friendly_description
  environment_name                 = var.environment_name
  network_rules                    = local.network_rules
  created_by_tag                   = var.created_by_tag
}

resource "azurerm_role_assignment" "maintainers_access_to_state_container" {
  for_each = toset(var.maintainers_group_object_ids)

  principal_id         = each.value
  scope                = module.terraform_state_container.container_resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
}

resource "time_sleep" "wait_for_rbac" {
  triggers = {
    maintainers   = jsonencode(var.maintainers_group_object_ids)
    state_storage = module.terraform_state_container.container_resource_manager_id
  }

  create_duration = "60s" # copied from caf enterprise scale
}
