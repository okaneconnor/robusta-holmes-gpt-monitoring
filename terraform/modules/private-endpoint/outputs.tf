output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = azurerm_private_endpoint.openai.id
}

output "private_endpoint_ip" {
  description = "Private IP address of the OpenAI endpoint"
  value       = azurerm_private_endpoint.openai.private_service_connection[0].private_ip_address
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = azurerm_private_dns_zone.openai.id
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = azurerm_private_dns_zone.openai.name
}
