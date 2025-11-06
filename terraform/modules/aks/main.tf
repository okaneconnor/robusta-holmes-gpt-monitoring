resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${var.resource_label}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-workload-${var.resource_label}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Federated identity credential for Robusta service account
resource "azurerm_federated_identity_credential" "robusta" {
  name                = "robusta-sa-credential"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  subject             = "system:serviceaccount:robusta:robusta-sa"
}

# Federated identity credential for Holmes GPT service account
resource "azurerm_federated_identity_credential" "holmesgpt" {
  name                = "holmesgpt-sa-credential"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  subject             = "system:serviceaccount:holmesgpt:holmesgpt-holmes-service-account"
}

# Federated identity credential for Slack Holmes Bot service account
resource "azurerm_federated_identity_credential" "slack_holmes_bot" {
  name                = "slack-holmes-bot-sa-credential"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  subject             = "system:serviceaccount:slack-holmes-bot:slack-holmes-bot-sa"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-${var.resource_label}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.resource_label}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_size
    vnet_subnet_id       = var.aks_subnet_id
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 5
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.tags["Environment"]
      "nodepoolos"    = "linux"
    }

    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != "" ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  auto_scaler_profile {
    balance_similar_node_groups      = false
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [1, 2]
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = var.node_size
  vnet_subnet_id        = var.aks_subnet_id
  auto_scaling_enabled  = true
  min_count             = 1
  max_count             = 10
  os_disk_size_gb       = 50

  node_labels = {
    "nodepool-type" = "workload"
    "environment"   = var.tags["Environment"]
    "nodepoolos"    = "linux"
  }

  node_taints = []

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  principal_id                     = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
  role_definition_name             = "Network Contributor"
  scope                            = var.aks_subnet_id
  skip_service_principal_aad_check = true

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_role_assignment" "aks_identity_operator" {
  principal_id                     = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
  role_definition_name             = "Managed Identity Operator"
  scope                            = azurerm_user_assigned_identity.workload.id
  skip_service_principal_aad_check = true

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_role_assignment" "aks_cluster_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  scope                = azurerm_kubernetes_cluster.aks_cluster.id

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_role_assignment" "aks_rbac_cluster_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks_cluster.id

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_role_assignment" "aks_user_access" {
  for_each             = toset(var.user_principal_ids)
  principal_id         = each.value
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks_cluster.id

  lifecycle {
    ignore_changes = all
  }
}