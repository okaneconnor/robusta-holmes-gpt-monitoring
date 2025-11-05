data "azurerm_client_config" "current" {}

# Create Entra ID group for Key Vault administrators
resource "azuread_group" "keyvault_admins" {
  display_name     = "KeyVault-Robusta-Admins-${var.environment}"
  description      = "Administrators with access to manage secrets in the Robusta Key Vault (${var.environment})"
  security_enabled = true

  owners = [
    data.azurerm_client_config.current.object_id
  ]

  members = concat(
    var.admin_user_object_ids,
    [data.azurerm_client_config.current.object_id] # Adds the service principal as a member
  )

  prevent_duplicate_names = true
}
