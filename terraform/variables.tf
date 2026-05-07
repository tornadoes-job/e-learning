variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "elearning"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
  default     = "dev"

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

# PostgreSQL
variable "db_admin_username" {
  type        = string
  description = "PostgreSQL admin username"
  sensitive   = true
}

variable "db_admin_password" {
  type        = string
  description = "PostgreSQL admin password (minimum 8 characters, mix of upper, lower, numbers, special)"
  sensitive   = true

  validation {
    condition     = length(var.db_admin_password) >= 8
    error_message = "Password must be at least 8 characters"
  }
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "elearning"
}

variable "db_sku" {
  type        = string
  description = "PostgreSQL SKU"
  default     = "B_Standard_B1ms"
}

# Redis
variable "redis_capacity" {
  type        = number
  description = "Redis cache capacity"
  default     = 0
}

variable "redis_family" {
  type        = string
  description = "Redis cache family (C or P)"
  default     = "C"
}

variable "redis_sku" {
  type        = string
  description = "Redis cache SKU"
  default     = "Basic"
}

# Application
variable "frontend_url" {
  type        = string
  description = "Frontend URL"
  default     = "http://localhost:4200"
}

variable "jwt_secret" {
  type        = string
  description = "JWT secret"
  sensitive   = true
}

variable "jwt_refresh_secret" {
  type        = string
  description = "JWT refresh secret"
  sensitive   = true
}

variable "stripe_secret_key" {
  type        = string
  description = "Stripe secret key"
  sensitive   = true
  default     = "sk_test_placeholder"
}

variable "cloudinary_cloud_name" {
  type        = string
  description = "Cloudinary cloud name"
  sensitive   = true
}

variable "cloudinary_api_key" {
  type        = string
  description = "Cloudinary API key"
  sensitive   = true
}

variable "cloudinary_api_secret" {
  type        = string
  description = "Cloudinary API secret"
  sensitive   = true
}
