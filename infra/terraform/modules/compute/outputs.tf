output "api_hostname" {
  description = "The host name the tracking API answers on."
  value       = azurerm_linux_web_app.api.default_hostname
}

output "identity_principal_id" {
  description = "The principal the apps run as."
  value       = azurerm_user_assigned_identity.apps.principal_id
}
