variable "org" {
  description = "The short name of the organisation, the first part of every resource name."
  type        = string
  default     = "parcel"

  validation {
    condition     = can(regex("^[a-z]{3,8}$", var.org))
    error_message = "The organisation's short name is 3 to 8 lowercase letters."
  }
}

variable "environment" {
  description = "The environment this root module deploys: dev or prod."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment is dev or prod."
  }
}

variable "location" {
  description = "The Azure region everything is created in."
  type        = string
  default     = "westeurope"
}

variable "address_space" {
  description = "The address ranges of the environment's virtual network."
  type        = list(string)
}

variable "subnets" {
  description = "The subnets by tier: each one's address range, and the service it is delegated to, if any."
  type = map(object({
    address_prefix = string
    delegation     = optional(string)
  }))
}

variable "app_sku" {
  description = "The size of the App Service plan."
  type        = string
}

variable "postgres_sku" {
  description = "The size of the Postgres flexible server."
  type        = string
}

variable "storage_replication" {
  description = "How the label storage is replicated."
  type        = string
  default     = "ZRS"
}

variable "tags" {
  description = "Tags added to the ones every resource carries, such as a cost centre."
  type        = map(string)
  default     = {}
}
