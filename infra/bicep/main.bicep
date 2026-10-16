// Parcelpoint on Azure: one resource group per environment that holds the monitoring, the network, the data
// services, and the apps, each made by a module of ./modules. Every name is <kind>-<org>-<environment>[-<role>],
// and every resource carries the same tags.
// Deploy with: az deployment sub create --location westeurope --parameters main.prod.bicepparam

targetScope = 'subscription'

@description('The short name of the organisation, the first part of every resource name.')
@minLength(3)
@maxLength(8)
param org string = 'parcel'

@description('The environment this deployment makes.')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('The Azure region everything is created in.')
param location string = 'westeurope'

@description('The address range of the environment\'s virtual network.')
param addressSpace string

@description('The subnets by tier: each one\'s address range, and the service it is delegated to, if any.')
param subnets array

@description('The size of the App Service plan.')
param appSku string

@description('The size of the Postgres flexible server.')
param postgresSku string

@description('How the label storage is replicated.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GZRS'
])
param storageSku string = 'Standard_ZRS'

@description('Tags added to the ones every resource carries, such as a cost centre.')
param extraTags object = {}

var namePrefix = format('{0}-{1}', org, environment)

var tags = union(extraTags, {
  environment: environment
  application: 'parcelpoint'
  managed_by: 'bicep'
})

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: format('rg-{0}', namePrefix)
  location: location
  tags: tags
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    namePrefix: namePrefix
    location: location
    retentionDays: environment == 'prod' ? 90 : 30
    tags: tags
  }
}

module network 'modules/network.bicep' = {
  name: 'network'
  scope: rg
  params: {
    namePrefix: namePrefix
    location: location
    addressSpace: addressSpace
    subnets: subnets
    workspaceId: monitoring.outputs.workspaceId
    tags: tags
  }
}

module data 'modules/data.bicep' = {
  name: 'data'
  scope: rg
  params: {
    namePrefix: namePrefix
    location: location
    databaseSubnetId: network.outputs.subnetIds.data
    endpointSubnetId: network.outputs.subnetIds.endpoints
    postgresDnsZoneId: network.outputs.postgresDnsZoneId
    postgresSku: postgresSku
    storageSku: storageSku
    tags: tags
  }
}

module compute 'modules/compute.bicep' = {
  name: 'compute'
  scope: rg
  params: {
    namePrefix: namePrefix
    location: location
    appSubnetId: network.outputs.subnetIds.app
    appSku: appSku
    insightsConnectionString: monitoring.outputs.insightsConnectionString
    postgresFqdn: data.outputs.postgresFqdn
    postgresPasswordSecretUri: data.outputs.postgresPasswordSecretUri
    keyVaultName: data.outputs.keyVaultName
    storageAccountName: data.outputs.storageAccountName
    serviceBusNamespaceName: data.outputs.serviceBusNamespaceName
    carrierEventsQueue: data.outputs.carrierEventsQueue
    tags: tags
  }
}

output apiHostname string = compute.outputs.apiHostname
