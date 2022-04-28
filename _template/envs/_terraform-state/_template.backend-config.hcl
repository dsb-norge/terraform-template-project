# azurerm backend configuration for terraform state
# NOTE:
#   This configuration is just for managing Azure resources related to state.
#   Resources for the environment are managed in envs/[BOOTSTRAP_VALUE_ENV_NAME]

# This is for the [BOOTSTRAP_VALUE_ENV_NAME] environment.
resource_group_name  = "[BOOTSTRAP_VALUE_RG_NAME]"
storage_account_name = "[BOOTSTRAP_VALUE_STRG_ACC_NAME]"
container_name       = "[BOOTSTRAP_VALUE_STATE_NAME]"
key                  = "env.terraform-state"
