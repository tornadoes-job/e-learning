output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group name"
}

output "resource_group_id" {
  value       = azurerm_resource_group.main.id
  description = "Resource group ID"
}

output "container_registry_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "Container Registry login server"
}

output "container_registry_name" {
  value       = azurerm_container_registry.main.name
  description = "Container Registry name"
}

output "postgresql_fqdn" {
  value       = azurerm_postgresql_flexible_server.main.fqdn
  description = "PostgreSQL FQDN"
}

output "postgresql_database_name" {
  value       = azurerm_postgresql_flexible_server_database.main.name
  description = "PostgreSQL database name"
}

output "redis_hostname" {
  value       = azurerm_redis_cache.main.hostname
  description = "Redis hostname"
}

output "redis_port" {
  value       = azurerm_redis_cache.main.ssl_port
  description = "Redis SSL port"
}

output "backend_app_url" {
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
  description = "Backend Container App URL"
}

output "key_vault_id" {
  value       = azurerm_key_vault.main.id
  description = "Key Vault ID"
}

output "application_insights_instrumentation_key" {
  value       = azurerm_application_insights.backend.instrumentation_key
  sensitive   = true
  description = "Application Insights instrumentation key for backend"
}

output "application_insights_connection_string" {
  value       = azurerm_application_insights.backend.connection_string
  sensitive   = true
  description = "Application Insights connection string for backend"
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.main.id
  description = "Log Analytics Workspace ID"
}

output "monitor_dashboard_url" {
  value       = "https://portal.azure.com/#@/resource${azurerm_portal_dashboard.main.id}"
  description = "URL to Azure Monitor Dashboard"
}

output "alerts_created" {
  value = {
    high_cpu           = azurerm_monitor_metric_alert.high_cpu.name
    high_memory        = azurerm_monitor_metric_alert.high_memory.name
    high_error_rate    = azurerm_monitor_metric_alert.high_error_rate.name
    db_high_cpu        = azurerm_monitor_metric_alert.db_high_cpu.name
    redis_high_cpu     = azurerm_monitor_metric_alert.redis_high_cpu.name
  }
  description = "Created metric alerts for monitoring"
}

output "monitoring_setup_complete" {
  value       = "Application Insights + Log Analytics + 5 Metric Alerts + Dashboard configured"
  description = "Monitoring stack status"
}

output "key_vault_name" {
  value       = azurerm_key_vault.main.name
  description = "Key Vault name"
}

output "storage_account_name" {
  value       = azurerm_storage_account.frontend.name
  description = "Storage account name for frontend"
}

output "frontend_static_website_url" {
  value       = azurerm_storage_account.frontend.primary_web_endpoint
  description = "Static website URL for frontend"
}
