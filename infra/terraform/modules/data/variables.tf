variable "name_prefix" {
  description = "The prefix every name in the module starts with, such as parcel-prod."
  type        = string
}

variable "location" {
  description = "The Azure region of the data services."
  type        = string
}

variable "resource_group_name" {
  description = "The resource group the data services are created in."
  type        = string
}

variable "database_subnet_id" {
  description = "The subnet delegated to the Postgres flexible server."
  type        = string
}

variable "endpoint_subnet_id" {
  description = "The subnet that holds the private endpoints."
  type        = string
}

variable "postgres_dns_zone_id" {
  description = "The private DNS zone that resolves the database's name inside the network."
  type        = string
}

variable "postgres_sku" {
  description = "The size of the Postgres flexible server."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "The storage of the Postgres flexible server, in megabytes."
  type        = number
  default     = 32768

  validation {
    condition     = var.postgres_storage_mb >= 32768
    error_message = "A flexible server has at least 32 GiB of storage."
  }
}

variable "storage_replication" {
  description = "How the label storage is replicated: LRS, ZRS, or GZRS."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GZRS"], var.storage_replication)
    error_message = "Replication is one of LRS, ZRS, or GZRS."
  }
}

variable "tags" {
  description = "The tags every resource of the module carries."
  type        = map(string)
  default     = {}
}
