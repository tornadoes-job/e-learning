locals {
  common_tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
    CreatedDate = timestamp()
  }
}
