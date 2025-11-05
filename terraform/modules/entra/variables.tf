variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "admin_user_object_ids" {
  description = "List of user object IDs to add as members of the KeyVault admins group"
  type        = list(string)
  default     = []
}
