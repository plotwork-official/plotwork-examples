using './main.bicep'

param environment = 'prod'
param addressSpace = '10.20.0.0/16'
param appSku = 'P1v3'
param postgresSku = 'Standard_D2ds_v5'
param storageSku = 'Standard_ZRS'

param subnets = [
  {
    name: 'app'
    addressPrefix: '10.20.1.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  {
    name: 'data'
    addressPrefix: '10.20.2.0/24'
    delegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
  }
  {
    name: 'endpoints'
    addressPrefix: '10.20.3.0/24'
    delegation: ''
  }
]

param extraTags = {
  cost_centre: 'logistics-platform'
}
