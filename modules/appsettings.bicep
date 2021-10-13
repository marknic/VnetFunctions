param functionAppName string
param settings object

resource functionApp 'Microsoft.Web/sites@2021-01-01' existing = {
  name: functionAppName
}

resource appSettings 'Microsoft.Web/sites/config@2021-01-01' = {
  name: 'appsettings'
  parent: functionApp
  properties: settings
}
