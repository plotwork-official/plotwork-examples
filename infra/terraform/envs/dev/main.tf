# Parcelpoint in development: one resource group that holds the monitoring, the network, the data services, and the
# apps, each made by a module of ../../modules. Every name is <kind>-<org>-<environment>[-<role>], and every resource
# carries the same tags.

locals {
  name_prefix = format("%s-%s", var.org, var.environment)

  tags = merge(var.tags, {
    environment = var.environment
    application = "parcelpoint"
    managed_by  = "terraform"
  })
}

resource "azurerm_resource_group" "main" {
  name     = format("rg-%s", local.name_prefix)
  location = var.location
  tags     = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix         = local.name_prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  retention_days      = 30
  tags                = local.tags
}

module "network" {
  source = "../../modules/network"

  name_prefix                = local.name_prefix
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  address_space              = var.address_space
  subnets                    = var.subnets
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

module "data" {
  source = "../../modules/data"

  name_prefix          = local.name_prefix
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  database_subnet_id   = module.network.subnet_ids["data"]
  endpoint_subnet_id   = module.network.subnet_ids["endpoints"]
  postgres_dns_zone_id = module.network.postgres_dns_zone_id
  postgres_sku         = var.postgres_sku
  storage_replication  = var.storage_replication
  tags                 = local.tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix                 = local.name_prefix
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  app_subnet_id               = module.network.subnet_ids["app"]
  app_sku                     = var.app_sku
  postgres_fqdn               = module.data.postgres_fqdn
  postgres_password_secret_id = module.data.postgres_password_secret_id
  key_vault_id                = module.data.key_vault_id
  storage_account_id          = module.data.storage_account_id
  storage_account_name        = module.data.storage_account_name
  servicebus_namespace_id     = module.data.servicebus_namespace_id
  carrier_events_queue        = module.data.carrier_events_queue
  tags                        = local.tags

  application_insights_connection_string = module.monitoring.application_insights_connection_string
}
