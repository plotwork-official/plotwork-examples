output "postgres_fqdn" {
  description = "The private host name of the database."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "postgres_password_secret_id" {
  description = "The Key Vault secret that holds the database password, without its version."
  value       = azurerm_key_vault_secret.postgres_password.versionless_id
}

output "key_vault_id" {
  description = "The id of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "storage_account_id" {
  description = "The id of the storage account that holds label PDFs."
  value       = azurerm_storage_account.labels.id
}

output "storage_account_name" {
  description = "The name of the storage account that holds label PDFs."
  value       = azurerm_storage_account.labels.name
}

output "servicebus_namespace_id" {
  description = "The id of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.this.id
}

output "carrier_events_queue" {
  description = "The name of the queue carrier events arrive on."
  value       = azurerm_servicebus_queue.carrier_events.name
}
