using './main.bicep'

param environment = 'dev'
param addressSpace = '10.10.0.0/16'
param appSku = 'B1'
param postgresSku = 'Standard_B1ms'
param storageSku = 'Standard_LRS'

param subnets = [
  {
    name: 'app'
    addressPrefix: '10.10.1.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  {
    name: 'data'
    addressPrefix: '10.10.2.0/24'
    delegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
  }
  {
    name: 'endpoints'
    addressPrefix: '10.10.3.0/24'
    delegation: ''
  }
]

param extraTags = {
  cost_centre: 'logistics-platform'
}
