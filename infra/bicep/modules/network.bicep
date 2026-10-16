// The private network of one environment: a virtual network, one subnet per tier, and the DNS zone that resolves
// the database's private name.

@description('The prefix every name in the module starts with, such as parcel-prod.')
param namePrefix string

@description('The Azure region of the network.')
param location string

@description('The address range of the virtual network.')
param addressSpace string

@description('The subnets by tier: name, addressPrefix, and the service each is delegated to, if any.')
param subnets array

@description('The workspace the security group\'s flow events are sent to.')
param workspaceId string

@description('The tags every resource of the module carries.')
param tags object = {}

resource appNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: format('nsg-{0}-app', namePrefix)
  location: location
  tags: tags
}

resource appNsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-workspace'
  scope: appNsg
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: format('vnet-{0}', namePrefix)
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [for subnet in subnets: {
      name: format('snet-{0}-{1}', namePrefix, subnet.name)
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: subnet.name == 'app' ? { id: appNsg.id } : null
        delegations: empty(subnet.delegation) ? [] : [
          {
            name: 'delegation'
            properties: {
              serviceName: subnet.delegation
            }
          }
        ]
      }
    }]
  }
}

resource postgresDns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

resource postgresDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: postgresDns
  name: format('pdnslink-{0}', namePrefix)
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

@description('The id of each subnet, by tier.')
output subnetIds object = {
  app: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, format('snet-{0}-app', namePrefix))
  data: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, format('snet-{0}-data', namePrefix))
  endpoints: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, format('snet-{0}-endpoints', namePrefix))
}

@description('The id of the private DNS zone of the database.')
output postgresDnsZoneId string = postgresDns.id
