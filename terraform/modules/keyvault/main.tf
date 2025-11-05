data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "robusta" {
  name                = "kv-robusta-${var.resource_label}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true

  soft_delete_retention_days = 7
  purge_protection_enabled   = false # Set this to true for production use cases

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"

    virtual_network_subnet_ids = [var.aks_subnet_id]
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.robusta.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_role_assignment" "aks_secrets_user" {
  scope                = azurerm_key_vault.robusta.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_kubelet_identity_object_id

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_role_assignment" "workload_secrets_user" {
  scope                = azurerm_key_vault.robusta.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_identity_principal_id

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_role_assignment" "admin_group_secrets_officer" {
  scope                = azurerm_key_vault.robusta.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admin_group_object_id

  lifecycle {
    ignore_changes = all
  }
}
