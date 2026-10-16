// What runs Parcelpoint's code: the tracking API and the carrier event worker on one App Service plan, joined to
// the app subnet, with one managed identity that the data services grant access to.

@description('The prefix every name in the module starts with, such as parcel-prod.')
param namePrefix string

@description('The Azure region of the apps.')
param location string

@description('The subnet the apps are joined to for outbound traffic.')
param appSubnetId string

@description('The size of the App Service plan.')
@allowed([
  'B1'
  'S1'
  'P1v3'
  'P2v3'
])
param appSku string = 'B1'

@description('Where the apps send their telemetry.')
@secure()
param insightsConnectionString string

@description('The private host name of the database.')
param postgresFqdn string

@description('The Key Vault secret that holds the database password.')
param postgresPasswordSecretUri string

@description('The Key Vault the apps read secrets from.')
param keyVaultName string

@description('The storage account the API writes label PDFs to.')
param storageAccountName string

@description('The Service Bus namespace the worker reads carrier events from.')
param serviceBusNamespaceName string

@description('The name of the queue carrier events arrive on.')
param carrierEventsQueue string

@description('The tags every resource of the module carries.')
param tags object = {}

// The built-in roles the apps' identity is given, by what each is for.
var grants = [
  {
    name: 'labels'
    role: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
  }
  {
    name: 'events'
    role: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0' // Azure Service Bus Data Receiver
  }
  {
    name: 'vault'
    role: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
  }
]

resource vault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

resource labels 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  name: serviceBusNamespaceName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: format('id-{0}-apps', namePrefix)
  location: location
  tags: tags
}

@batchSize(1)
resource access 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for grant in grants: {
  name: guid(identity.id, grant.name, grant.role)
  scope: grant.name == 'labels' ? labels : grant.name == 'events' ? serviceBus : vault
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', grant.role)
  }
}]

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: format('asp-{0}', namePrefix)
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: appSku
  }
  properties: {
    reserved: true
  }
}

resource api 'Microsoft.Web/sites@2024-04-01' = {
  name: format('app-{0}-api', namePrefix)
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    serverFarmId: plan.id
    virtualNetworkSubnetId: appSubnetId
    httpsOnly: true
    keyVaultReferenceIdentity: identity.id
    siteConfig: {
      linuxFxVersion: 'NODE|22-lts'
      alwaysOn: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: insightsConnectionString
        }
        {
          name: 'DATABASE_HOST'
          value: postgresFqdn
        }
        {
          name: 'DATABASE_PASSWORD'
          value: format('@Microsoft.KeyVault(SecretUri={0})', postgresPasswordSecretUri)
        }
        {
          name: 'LABELS_ACCOUNT'
          value: labels.name
        }
      ]
    }
  }
}

resource worker 'Microsoft.Web/sites@2024-04-01' = {
  name: format('func-{0}-events', namePrefix)
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    serverFarmId: plan.id
    virtualNetworkSubnetId: appSubnetId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|22'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: insightsConnectionString
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: labels.name
        }
        {
          name: 'CARRIER_EVENTS_QUEUE'
          value: carrierEventsQueue
        }
        {
          name: 'DATABASE_HOST'
          value: postgresFqdn
        }
      ]
    }
  }
}

output apiHostname string = api.properties.defaultHostName
