
param functionAppName string

param settings object

module appSettings 'modules/appsettings.bicep' = {
  name: functionAppName
  params: {
    functionAppName: functionAppName
    settings: settings
  }
}
