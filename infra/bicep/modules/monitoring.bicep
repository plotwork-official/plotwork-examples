// Where every part of an environment sends its logs and telemetry: one Log Analytics workspace, and the
// Application Insights component the apps report to.

@description('The prefix every name in the module starts with, such as parcel-prod.')
param namePrefix string

@description('The Azure region of the workspace.')
param location string

@description('How many days the workspace keeps logs.')
@minValue(30)
@maxValue(730)
param retentionDays int = 30

@description('The tags every resource of the module carries.')
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: format('log-{0}', namePrefix)
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionDays
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: format('appi-{0}', namePrefix)
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

@description('The id of the workspace every diagnostic setting sends to.')
output workspaceId string = workspace.id

@description('Where the apps send their telemetry.')
output insightsConnectionString string = insights.properties.ConnectionString
