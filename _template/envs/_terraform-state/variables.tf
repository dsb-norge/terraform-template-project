# No validation, this is handled by the module itself.
variable "subscription_number" {
  description = "Subscription number to use when naming resources."
  type        = number
}
variable "resource_group_number" {
  description = "Resource group number to use when naming resources."
  type        = number
}
variable "application_name" {
  description = "Name of the application to use when naming resources."
  type        = string
}
variable "application_name_short" {
  description = "Short name of the application to use when naming resources eg. for storage account name."
  type        = string
}
variable "application_friendly_description" {
  description = "Friendly description of the application to use when naming resources."
  type        = string
}
variable "environment_name" {
  description = "Name of the environment to use when naming resources."
  type        = string
}
variable "created_by_tag" {
  description = "Tag to use when naming resources."
  type        = string
}
