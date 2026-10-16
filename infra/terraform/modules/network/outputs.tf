output "virtual_network_id" {
  description = "The id of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "The id of each subnet, by tier."
  value       = { for tier, subnet in azurerm_subnet.this : tier => subnet.id }
}

output "postgres_dns_zone_id" {
  description = "The id of the private DNS zone of the database."
  value       = azurerm_private_dns_zone.postgres.id
}
