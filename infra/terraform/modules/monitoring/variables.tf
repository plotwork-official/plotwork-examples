variable "name_prefix" {
  description = "The prefix every name in the module starts with, such as parcel-prod."
  type        = string
}

variable "location" {
  description = "The Azure region of the workspace."
  type        = string
}

variable "resource_group_name" {
  description = "The resource group the workspace is created in."
  type        = string
}

variable "retention_days" {
  description = "How many days the workspace keeps logs."
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 30 && var.retention_days <= 730
    error_message = "A workspace keeps logs for 30 to 730 days."
  }
}

variable "tags" {
  description = "The tags every resource of the module carries."
  type        = map(string)
  default     = {}
}
