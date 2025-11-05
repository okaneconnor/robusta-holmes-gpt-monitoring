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

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet where the private endpoint will be created"
  type        = string
}

variable "openai_account_id" {
  description = "Resource ID of the Azure OpenAI account"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network to link the private DNS zone"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
