# What runs Parcelpoint's code: the tracking API and the carrier event worker on one App Service plan, joined to
# the app subnet, with one managed identity that the data services grant access to.

locals {
  # Each grant the apps' identity is given, by what it is for.
  grants = {
    labels = { scope = var.storage_account_id, role = "Storage Blob Data Contributor" }
    events = { scope = var.servicebus_namespace_id, role = "Azure Service Bus Data Receiver" }
    vault  = { scope = var.key_vault_id, role = "Key Vault Secrets User" }
  }
}

resource "azurerm_user_assigned_identity" "apps" {
  name                = format("id-%s-apps", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "apps" {
  for_each = local.grants

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.apps.principal_id
}

resource "azurerm_service_plan" "this" {
  name                = format("asp-%s", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_sku
  tags                = var.tags
}

resource "azurerm_linux_web_app" "api" {
  name                      = format("app-%s-api", var.name_prefix)
  location                  = var.location
  resource_group_name       = var.resource_group_name
  service_plan_id           = azurerm_service_plan.this.id
  virtual_network_subnet_id = var.app_subnet_id
  https_only                = true
  tags                      = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apps.id]
  }

  site_config {
    always_on = true
    application_stack {
      node_version = "22-lts"
    }
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection_string
    DATABASE_HOST                         = var.postgres_fqdn
    DATABASE_PASSWORD                     = format("@Microsoft.KeyVault(SecretUri=%s)", var.postgres_password_secret_id)
    LABELS_ACCOUNT                        = var.storage_account_name
  }
}

resource "azurerm_linux_function_app" "worker" {
  name                          = format("func-%s-events", var.name_prefix)
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.this.id
  virtual_network_subnet_id     = var.app_subnet_id
  storage_account_name          = var.storage_account_name
  storage_uses_managed_identity = true
  tags                          = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apps.id]
  }

  site_config {
    application_stack {
      node_version = "22"
    }
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection_string
    CARRIER_EVENTS_QUEUE                  = var.carrier_events_queue
    DATABASE_HOST                         = var.postgres_fqdn
  }
}
