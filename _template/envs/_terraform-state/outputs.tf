output "container_name" {
  description = "Name of the storage container created for terraform backend state."
  value       = module.terraform_state_container.container_name
}

output "resource_group_name" {
  description = "Name of the resource group created for terraform backend state."
  value       = module.terraform_state_container.resource_group_name
}

output "storage_account_name" {
  description = "Name of the storage account created for terraform backend state."
  value       = module.terraform_state_container.storage_account_name
}
