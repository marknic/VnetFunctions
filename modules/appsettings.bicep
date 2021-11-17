@description('Name of the Function App to update with new settings.')
param functionAppName string

@description('The settings object to put in the Function App.')
param settings object

//
// Resources
//
resource functionApp 'Microsoft.Web/sites@2021-01-01' existing = {
  name: functionAppName
}

resource appSettings 'Microsoft.Web/sites/config@2021-01-01' = {
  name: 'appsettings'
  parent: functionApp
  properties: settings
}
