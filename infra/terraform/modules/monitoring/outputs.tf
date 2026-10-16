output "log_analytics_workspace_id" {
  description = "The id of the workspace every diagnostic setting sends to."
  value       = azurerm_log_analytics_workspace.this.id
}

output "application_insights_connection_string" {
  description = "Where the apps send their telemetry."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}
