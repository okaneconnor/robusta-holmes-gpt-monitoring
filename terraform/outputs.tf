output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "workload_identity_client_id" {
  description = "Client ID of the AKS workload identity"
  value       = module.aks.workload_identity_client_id
}

output "tenant_id" {
  description = "Azure tenant ID"
  value       = module.keyvault.tenant_id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "keyvault_admin_group_name" {
  description = "Name of the Key Vault admin group"
  value       = module.entra.keyvault_admin_group_name
}

output "keyvault_admin_group_id" {
  description = "Object ID of the Key Vault admin group"
  value       = module.entra.keyvault_admin_group_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.network.vnet_name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.network.aks_subnet_id
}

output "openai_account_name" {
  description = "Name of the Azure OpenAI account"
  value       = module.openai.openai_account_name
}

output "openai_endpoint" {
  description = "Endpoint URL for the Azure OpenAI service"
  value       = module.openai.openai_endpoint
}

output "openai_deployment_name" {
  description = "Name of the GPT-4o deployment"
  value       = module.openai.openai_deployment_name
}

output "openai_private_endpoint_ip" {
  description = "Private IP address of the Azure OpenAI endpoint"
  value       = module.private_endpoint.private_endpoint_ip
}

output "openai_private_dns_zone" {
  description = "Private DNS zone for Azure OpenAI"
  value       = module.private_endpoint.private_dns_zone_name
}

# ACR Outputs
output "acr_login_server" {
  description = "Login server URL for the ACR"
  value       = module.acr.acr_login_server
}

output "acr_name" {
  description = "Name of the ACR"
  value       = module.acr.acr_name
}
