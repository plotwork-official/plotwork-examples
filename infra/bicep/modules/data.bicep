// Where Parcelpoint keeps its state: parcels and their events in Postgres, label PDFs in blob storage, carrier
// events on a Service Bus queue, and the database password in Key Vault.

@description('The prefix every name in the module starts with, such as parcel-prod.')
param namePrefix string

@description('The Azure region of the data services.')
param location string

@description('The subnet delegated to the Postgres flexible server.')
param databaseSubnetId string

@description('The subnet that holds the private endpoints.')
param endpointSubnetId string

@description('The private DNS zone that resolves the database\'s name inside the network.')
param postgresDnsZoneId string

@description('The size of the Postgres flexible server.')
param postgresSku string = 'Standard_B1ms'

@description('How the label storage is replicated.')
param storageSku string = 'Standard_LRS'

@description('The password of the database administrator, generated once and kept in Key Vault.')
@secure()
param postgresPassword string = newGuid()

@description('The tags every resource of the module carries.')
param tags object = {}

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: format('psql-{0}', namePrefix)
  location: location
  tags: tags
  sku: {
    name: postgresSku
    tier: startsWith(postgresSku, 'Standard_B') ? 'Burstable' : 'GeneralPurpose'
  }
  properties: {
    version: '16'
    administratorLogin: 'parcelpoint'
    administratorLoginPassword: postgresPassword
    network: {
      delegatedSubnetResourceId: databaseSubnetId
      privateDnsZoneArmResourceId: postgresDnsZoneId
      publicNetworkAccess: 'Disabled'
    }
    storage: {
      storageSizeGB: 32
    }
  }

  resource tracking 'databases' = {
    name: 'tracking'
    properties: {
      charset: 'UTF8'
      collation: 'en_US.utf8'
    }
  }
}

resource labels 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: replace(format('st{0}labels', namePrefix), '-', '')
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: storageSku
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }

  resource blob 'blobServices' = {
    name: 'default'

    resource container 'containers' = {
      name: 'labels'
    }
  }
}

resource labelsEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: format('pe-{0}-labels', namePrefix)
  location: location
  tags: tags
  properties: {
    subnet: {
      id: endpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: labels.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: format('sb-{0}', namePrefix)
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }

  resource carrierEvents 'queues' = {
    name: 'carrier-events'
    properties: {
      maxDeliveryCount: 10
      lockDuration: 'PT1M'
      deadLetteringOnMessageExpiration: true
    }
  }
}

resource vault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: format('kv-{0}', namePrefix)
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enablePurgeProtection: true
  }

  resource postgresPasswordSecret 'secrets' = {
    name: 'postgres-password'
    properties: {
      value: postgresPassword
    }
  }
}

output postgresFqdn string = postgres.properties.fullyQualifiedDomainName
output postgresPasswordSecretUri string = vault::postgresPasswordSecret.properties.secretUri
output keyVaultName string = vault.name
output storageAccountName string = labels.name
output serviceBusNamespaceName string = serviceBus.name
output carrierEventsQueue string = serviceBus::carrierEvents.name
