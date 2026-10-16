variable "name_prefix" {
  description = "The prefix every name in the module starts with, such as parcel-prod."
  type        = string
}

variable "location" {
  description = "The Azure region of the apps."
  type        = string
}

variable "resource_group_name" {
  description = "The resource group the apps are created in."
  type        = string
}

variable "app_subnet_id" {
  description = "The subnet the apps are joined to for outbound traffic."
  type        = string
}

variable "app_sku" {
  description = "The size of the App Service plan."
  type        = string
  default     = "B1"

  validation {
    condition     = can(regex("^(B|S|P[0-9]v[0-9])[0-9]?$", var.app_sku))
    error_message = "Use a Basic, Standard, or Premium plan size, such as B1 or P1v3."
  }
}

variable "application_insights_connection_string" {
  description = "Where the apps send their telemetry."
  type        = string
  sensitive   = true
}

variable "postgres_fqdn" {
  description = "The private host name of the database."
  type        = string
}

variable "postgres_password_secret_id" {
  description = "The Key Vault secret that holds the database password."
  type        = string
}

variable "key_vault_id" {
  description = "The Key Vault the apps read secrets from."
  type        = string
}

variable "storage_account_id" {
  description = "The storage account the API writes label PDFs to."
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account the API writes label PDFs to."
  type        = string
}

variable "servicebus_namespace_id" {
  description = "The Service Bus namespace the worker reads carrier events from."
  type        = string
}

variable "carrier_events_queue" {
  description = "The name of the queue carrier events arrive on."
  type        = string
}

variable "tags" {
  description = "The tags every resource of the module carries."
  type        = map(string)
  default     = {}
}
