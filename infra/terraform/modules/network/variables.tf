variable "name_prefix" {
  description = "The prefix every name in the module starts with, such as parcel-prod."
  type        = string
}

variable "location" {
  description = "The Azure region of the network."
  type        = string
}

variable "resource_group_name" {
  description = "The resource group the network is created in."
  type        = string
}

variable "address_space" {
  description = "The address ranges of the virtual network."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "Give the network at least one address range."
  }
}

variable "subnets" {
  description = "The subnets by tier: each one's address range, and the service it is delegated to, if any."
  type = map(object({
    address_prefix = string
    delegation     = optional(string)
  }))
}

variable "log_analytics_workspace_id" {
  description = "The workspace the security group's flow events are sent to."
  type        = string
}

variable "tags" {
  description = "The tags every resource of the module carries."
  type        = map(string)
  default     = {}
}
