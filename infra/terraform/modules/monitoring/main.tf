# Where every part of an environment sends its logs and telemetry: one Log Analytics workspace, and the
# Application Insights component the apps report to.

resource "azurerm_log_analytics_workspace" "this" {
  name                = format("log-%s", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = format("appi-%s", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}
