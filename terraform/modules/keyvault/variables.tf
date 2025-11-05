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

variable "aks_subnet_id" {
  description = "ID of the AKS subnet for network access"
  type        = string
}

variable "aks_kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity"
  type        = string
}

variable "workload_identity_principal_id" {
  description = "Principal ID of the workload identity"
  type        = string
}

variable "admin_group_object_id" {
  description = "Object ID of the Entra ID group for Key Vault administrators"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
