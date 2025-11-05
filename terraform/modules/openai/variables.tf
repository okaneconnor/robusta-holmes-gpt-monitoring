variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_label" {
  description = "Unique label for resources"
  type        = string
}

variable "workload_identity_principal_id" {
  description = "Principal ID of the workload identity (for Holmes GPT)"
  type        = string
}

variable "admin_group_object_id" {
  description = "Object ID of the Entra ID group for OpenAI administrators"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store the OpenAI API key"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
