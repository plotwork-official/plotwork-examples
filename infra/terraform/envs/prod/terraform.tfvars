environment         = "prod"
location            = "westeurope"
address_space       = ["10.20.0.0/16"]
app_sku             = "P1v3"
postgres_sku        = "GP_Standard_D2ds_v5"
storage_replication = "ZRS"

subnets = {
  app = {
    address_prefix = "10.20.1.0/24"
    delegation     = "Microsoft.Web/serverFarms"
  }
  data = {
    address_prefix = "10.20.2.0/24"
    delegation     = "Microsoft.DBforPostgreSQL/flexibleServers"
  }
  endpoints = {
    address_prefix = "10.20.3.0/24"
  }
}

tags = {
  cost_centre = "logistics-platform"
}
