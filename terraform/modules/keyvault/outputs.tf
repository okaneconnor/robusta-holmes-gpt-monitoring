output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.robusta.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.robusta.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.robusta.vault_uri
}

output "tenant_id" {
  description = "Tenant ID for the Key Vault"
  value       = azurerm_key_vault.robusta.tenant_id
}

output "deployer_role_assignment_id" {
  description = "ID of the deployer role assignment (for dependency management)"
  value       = azurerm_role_assignment.deployer_secrets_officer.id
}
