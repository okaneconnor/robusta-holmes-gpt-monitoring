resource "azurerm_resource_group" "mcp_gateway" {
  name     = "rg-robusta-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

module "entra" {
  source = "./modules/entra"

  environment           = var.environment
  admin_user_object_ids = var.admin_user_object_ids
}

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.mcp_gateway.name
  location            = azurerm_resource_group.mcp_gateway.location
  resource_label      = local.resource_label
  vnet_address_space  = var.vnet_address_space
  tags                = local.common_tags
}

module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.mcp_gateway.name
  location            = azurerm_resource_group.mcp_gateway.location
  resource_label      = local.resource_label
  aks_subnet_id       = module.network.aks_subnet_id
  node_count          = var.aks_node_count
  node_size           = var.aks_node_size
  kubernetes_version  = var.kubernetes_version
  user_principal_ids  = var.admin_user_object_ids
  tags                = local.common_tags
}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name            = azurerm_resource_group.mcp_gateway.name
  location                       = azurerm_resource_group.mcp_gateway.location
  resource_label                 = local.resource_label
  aks_subnet_id                  = module.network.aks_subnet_id
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  workload_identity_principal_id = module.aks.workload_identity_principal_id
  admin_group_object_id          = module.entra.keyvault_admin_group_id
  tags                           = local.common_tags
}

module "openai" {
  source = "./modules/openai"

  resource_group_name            = azurerm_resource_group.mcp_gateway.name
  location                       = azurerm_resource_group.mcp_gateway.location
  resource_label                 = local.resource_label
  workload_identity_principal_id = module.aks.workload_identity_principal_id
  admin_group_object_id          = module.entra.keyvault_admin_group_id
  key_vault_id                   = module.keyvault.key_vault_id
  tags                           = local.common_tags

  depends_on = [module.keyvault]
}

module "private_endpoint" {
  source = "./modules/private-endpoint"

  resource_group_name        = azurerm_resource_group.mcp_gateway.name
  location                   = azurerm_resource_group.mcp_gateway.location
  resource_label             = local.resource_label
  private_endpoint_subnet_id = module.network.aks_subnet_id
  openai_account_id          = module.openai.openai_account_id
  vnet_id                    = module.network.vnet_id
  tags                       = local.common_tags
  depends_on                 = [module.openai]
}

module "acr" {
  source = "./modules/acr"

  acr_name                       = "acrrobusta${local.resource_label}"
  resource_group_name            = azurerm_resource_group.mcp_gateway.name
  location                       = azurerm_resource_group.mcp_gateway.location
  sku                            = "Basic"
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  tags                           = local.common_tags
}