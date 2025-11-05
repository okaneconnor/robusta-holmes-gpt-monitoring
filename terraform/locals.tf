locals {
  resource_label = var.environment
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "MCP-Gateway"
    }
  )
}