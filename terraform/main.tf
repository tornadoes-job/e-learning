terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Using local backend for now - migrate to Azure Storage by running:
  # terraform init -migrate-state -backend-config=backend.tfvars
  backend "local" {
    path = ".terraform/state/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }

  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.app_name}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# Key Vault pour les secrets
resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.app_name}-${var.environment}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Update",
      "Delete",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Update",
      "Delete",
    ]
  }

  tags = local.common_tags
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "db-connection-string"
  value        = "postgresql://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.db_name}"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "jwt_refresh_secret" {
  name         = "jwt-refresh-secret"
  value        = var.jwt_refresh_secret
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "stripe_secret_key" {
  name         = "stripe-secret-key"
  value        = var.stripe_secret_key
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "cloudinary_api_secret" {
  name         = "cloudinary-api-secret"
  value        = var.cloudinary_api_secret
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.main.admin_password
  key_vault_id = azurerm_key_vault.main.id
}

# RBAC - Allow Container App to read Key Vault secrets
resource "azurerm_role_assignment" "container_app_key_vault_access" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_app.backend.identity[0].principal_id
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.app_name, "-", "")}${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  admin_enabled       = true

  network_rule_bypass_option = "AzureServices"

  tags = local.common_tags
}

# Service Principal pour ACR Pull
resource "azurerm_container_registry_scope_map" "pull" {
  name                    = "pull-scope"
  container_registry_name = azurerm_container_registry.main.name
  resource_group_name     = azurerm_resource_group.main.name
  actions = [
    "repositories/*/metadata/read",
    "repositories/*/content/read",
  ]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "ps-${var.app_name}-${var.environment}-db"
  location               = var.db_location != "" ? var.db_location : azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  version                = "15"
  storage_mb             = 32768
  sku_name               = var.db_sku

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = local.common_tags
}

# Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Allow Azure services to PostgreSQL
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL allows connections via firewall rule for Azure services
# VNet integration not needed as Container App connects via FQDN with firewall rule

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.app_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku
  minimum_tls_version = "1.2"

  tags = local.common_tags
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                           = "cae-${var.app_name}-${var.environment}"
  location                       = azurerm_resource_group.main.location
  resource_group_name            = azurerm_resource_group.main.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id       = azurerm_subnet.container_apps.id
  internal_load_balancer_enabled = false

  tags = local.common_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.app_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# Application Insights (APM - Application Performance Monitoring)
resource "azurerm_application_insights" "backend" {
  name                = "ai-${var.app_name}-backend-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  tags = local.common_tags
}

# Alert for High CPU Usage
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-high-cpu-${var.app_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_app.backend.id]
  description         = "Alert when CPU usage is high"

  criteria {
    metric_name      = "CpuUsagePercentage"
    operator         = "GreaterThan"
    threshold        = 80
    aggregation      = "Average"
    metric_namespace = "Microsoft.App/containerApps"
  }

  window_size   = "PT5M"
  frequency     = "PT1M"
  auto_mitigate = true

  tags = local.common_tags
}

# Alert for High Memory Usage
resource "azurerm_monitor_metric_alert" "high_memory" {
  name                = "alert-high-memory-${var.app_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_app.backend.id]
  description         = "Alert when memory usage is high"

  criteria {
    metric_name      = "MemoryUsagePercentage"
    operator         = "GreaterThan"
    threshold        = 85
    aggregation      = "Average"
    metric_namespace = "Microsoft.App/containerApps"
  }

  window_size   = "PT5M"
  frequency     = "PT1M"
  auto_mitigate = true

  tags = local.common_tags
}

# Alert for High Error Rate
resource "azurerm_monitor_metric_alert" "high_error_rate" {
  name                = "alert-high-errors-${var.app_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.backend.id]
  description         = "Alert when the Application Insights failed request count is high"

  criteria {
    metric_name      = "requests/failed"
    operator         = "GreaterThan"
    threshold        = 10
    aggregation      = "Count"
    metric_namespace = "microsoft.insights/components"
  }

  window_size   = "PT5M"
  frequency     = "PT1M"
  auto_mitigate = true

  tags = local.common_tags
}

# Alert for PostgreSQL High CPU
resource "azurerm_monitor_metric_alert" "db_high_cpu" {
  name                = "alert-db-high-cpu-${var.app_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
  description         = "Alert when PostgreSQL CPU usage is high"

  criteria {
    metric_name      = "cpu_percent"
    operator         = "GreaterThan"
    threshold        = 80
    aggregation      = "Average"
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
  }

  window_size   = "PT5M"
  frequency     = "PT1M"
  auto_mitigate = true

  tags = local.common_tags
}

# Alert for Redis High CPU
resource "azurerm_monitor_metric_alert" "redis_high_cpu" {
  name                = "alert-redis-high-cpu-${var.app_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_redis_cache.main.id]
  description         = "Alert when Redis CPU usage is high"

  criteria {
    metric_name      = "percentProcessorTime"
    operator         = "GreaterThan"
    threshold        = 75
    aggregation      = "Average"
    metric_namespace = "Microsoft.Cache/redis"
  }

  window_size   = "PT5M"
  frequency     = "PT1M"
  auto_mitigate = true

  tags = local.common_tags
}

# Container App - Backend
resource "azurerm_container_app" "backend" {
  name                         = "ca-${var.app_name}-backend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_postgresql_flexible_server_database.main,
    azurerm_redis_cache.main,
    azurerm_key_vault_secret.db_connection_string,
    azurerm_key_vault_secret.jwt_secret
  ]

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 3000

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    server               = azurerm_container_registry.main.login_server
    username             = azurerm_container_registry.main.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.main.admin_password
  }

  template {
    container {
      name   = "backend"
      image  = "${azurerm_container_registry.main.login_server}/e-learning-backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "NODE_ENV"
        value = var.environment == "prod" ? "production" : "development"
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.db_name}"
      }

      env {
        name  = "REDIS_URL"
        value = "rediss://:${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}"
      }

      env {
        name  = "FRONTEND_URL"
        value = var.frontend_url
      }

      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }

      env {
        name  = "JWT_REFRESH_SECRET"
        value = var.jwt_refresh_secret
      }

      env {
        name  = "STRIPE_SECRET_KEY"
        value = var.stripe_secret_key
      }

      env {
        name  = "CLOUDINARY_CLOUD_NAME"
        value = var.cloudinary_cloud_name
      }

      env {
        name  = "CLOUDINARY_API_KEY"
        value = var.cloudinary_api_key
      }

      env {
        name  = "CLOUDINARY_API_SECRET"
        value = var.cloudinary_api_secret
      }
    }

    min_replicas = 1
    max_replicas = var.environment == "prod" ? 5 : 2
  }

  tags = local.common_tags
}

# Storage Account pour frontend static
resource "azurerm_storage_account" "frontend" {
  name                       = "st${replace(var.app_name, "-", "")}${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  account_tier               = "Standard"
  account_replication_type   = "GRS"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  tags = local.common_tags
}

resource "azurerm_storage_account_static_website" "frontend" {
  storage_account_id = azurerm_storage_account.frontend.id
  index_document     = "index.html"
  error_404_document = "index.html"
}

# CDN is disabled because AzureRM no longer allows creating new CDN resources after Oct 1, 2025.
# Frontend will be served via Storage Static Website directly.

# Monitor Dashboard - Disabled due to complexity
# Use Azure Portal directly for monitoring instead
# The monitoring stack is configured via Application Insights + Log Analytics + Metric Alerts
