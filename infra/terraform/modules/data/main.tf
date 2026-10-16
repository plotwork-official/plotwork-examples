# Where Parcelpoint keeps its state: parcels and their events in Postgres, label PDFs in blob storage, carrier
# events on a Service Bus queue, and the database password in Key Vault.

data "azurerm_client_config" "current" {}

resource "random_password" "postgres" {
  length  = 32
  special = true
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = format("psql-%s", var.name_prefix)
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = "16"
  sku_name                      = var.postgres_sku
  storage_mb                    = var.postgres_storage_mb
  delegated_subnet_id           = var.database_subnet_id
  private_dns_zone_id           = var.postgres_dns_zone_id
  public_network_access_enabled = false
  administrator_login           = "parcelpoint"
  administrator_password        = random_password.postgres.result
  zone                          = "1"
  tags                          = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "tracking" {
  name      = "tracking"
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_storage_account" "labels" {
  name                          = replace(format("st%slabels", var.name_prefix), "-", "")
  location                      = var.location
  resource_group_name           = var.resource_group_name
  account_tier                  = "Standard"
  account_replication_type      = var.storage_replication
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_storage_container" "labels" {
  name               = "labels"
  storage_account_id = azurerm_storage_account.labels.id
}

resource "azurerm_private_endpoint" "labels" {
  name                = format("pe-%s-labels", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "blob"
    private_connection_resource_id = azurerm_storage_account.labels.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_servicebus_namespace" "this" {
  name                = format("sb-%s", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "carrier_events" {
  name                                 = "carrier-events"
  namespace_id                         = azurerm_servicebus_namespace.this.id
  max_delivery_count                   = 10
  lock_duration                        = "PT1M"
  dead_lettering_on_message_expiration = true
}

resource "azurerm_key_vault" "this" {
  name                      = format("kv-%s", var.name_prefix)
  location                  = var.location
  resource_group_name       = var.resource_group_name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
  purge_protection_enabled  = true
  tags                      = var.tags
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.this.id
}
