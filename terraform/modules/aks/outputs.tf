output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
}

output "workload_identity_client_id" {
  description = "Client ID of the workload identity"
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID (Object ID) of the workload identity"
  value       = azurerm_user_assigned_identity.workload.principal_id
}

output "node_resource_group" {
  description = "Name of the AKS node resource group"
  value       = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}

output "kube_admin_host" {
  description = "Admin Kubernetes API server endpoint"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_admin_config[0].host
}

output "kube_admin_client_certificate" {
  description = "Admin client certificate"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_admin_config[0].client_certificate
  sensitive   = true
}

output "kube_admin_client_key" {
  description = "Admin client key"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_admin_config[0].client_key
  sensitive   = true
}

output "kube_admin_cluster_ca_certificate" {
  description = "Admin cluster CA certificate"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_admin_config[0].cluster_ca_certificate
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server endpoint"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
}

output "client_certificate" {
  description = "Client certificate"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate
  sensitive   = true
}