output "openai_account_id" {
  description = "ID of the Azure OpenAI Cognitive Services account"
  value       = azurerm_cognitive_account.openai.id
}

output "openai_account_name" {
  description = "Name of the Azure OpenAI account"
  value       = azurerm_cognitive_account.openai.name
}

output "openai_endpoint" {
  description = "Endpoint URL for the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_deployment_name" {
  description = "Name of the GPT-4o deployment"
  value       = azurerm_cognitive_deployment.gpt4o.name
}

output "openai_principal_id" {
  description = "Principal ID of the OpenAI managed identity"
  value       = azurerm_cognitive_account.openai.identity[0].principal_id
}
