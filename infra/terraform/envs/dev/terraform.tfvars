environment         = "dev"
location            = "westeurope"
address_space       = ["10.10.0.0/16"]
app_sku             = "B1"
postgres_sku        = "B_Standard_B1ms"
storage_replication = "LRS"

subnets = {
  app = {
    address_prefix = "10.10.1.0/24"
    delegation     = "Microsoft.Web/serverFarms"
  }
  data = {
    address_prefix = "10.10.2.0/24"
    delegation     = "Microsoft.DBforPostgreSQL/flexibleServers"
  }
  endpoints = {
    address_prefix = "10.10.3.0/24"
  }
}

tags = {
  cost_centre = "logistics-platform"
}
