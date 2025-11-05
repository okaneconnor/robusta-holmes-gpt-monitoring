output "keyvault_admin_group_id" {
  description = "Object ID of the Key Vault admin group"
  value       = azuread_group.keyvault_admins.object_id
}

output "keyvault_admin_group_name" {
  description = "Name of the Key Vault admin group"
  value       = azuread_group.keyvault_admins.display_name
}
