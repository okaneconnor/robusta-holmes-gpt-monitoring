data "azurerm_client_config" "current" {}

resource "azurerm_cognitive_account" "openai" {
  name                = "cog-openai-${var.resource_label}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = "S0"

  # Custom subdomain is required for private endpoints
  # Must be globally unique across all Azure OpenAI resources
  custom_subdomain_name = "openai-holmes-${var.resource_label}-${substr(md5(var.resource_group_name), 0, 6)}"

  # Security: Disable public network access
  # Access will be via private endpoint only
  public_network_access_enabled = false

  # Enable local authentication to retrieve API keys
  # Required to access primary_access_key attribute
  local_auth_enabled = true

  # Network ACLs - Deny all public access
  # Private endpoint handles private connectivity
  network_acls {
    default_action = "Deny"
  }

  # Enable system-assigned managed identity for secure access
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Deploy GPT-4o model for AI operations with large context window
# GPT-4o has 128K token context vs 4K for GPT-3.5-turbo
resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-11-20"
  }

  sku {
    name     = "Standard"
    capacity = 30 # 30K TPM for better responsiveness
  }
}

# Grant current user (deployer) Cognitive Services OpenAI Contributor access
resource "azurerm_role_assignment" "deployer_openai_contributor" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = data.azurerm_client_config.current.object_id

  lifecycle {
    ignore_changes = all
  }
}

# Grant workload identity access to use OpenAI (for Holmes GPT)
resource "azurerm_role_assignment" "workload_openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = var.workload_identity_principal_id

  lifecycle {
    ignore_changes = all
  }
}

# Grant admin group access to manage OpenAI
resource "azurerm_role_assignment" "admin_group_openai_contributor" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = var.admin_group_object_id

  lifecycle {
    ignore_changes = all
  }
}

# Store OpenAI API key in Key Vault
resource "azurerm_key_vault_secret" "openai_api_key" {
  name         = "openai-api-key"
  value        = azurerm_cognitive_account.openai.primary_access_key
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_cognitive_account.openai]
}
