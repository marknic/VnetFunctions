
@description('App Service Plan resource location.')
param location string

@description('App Service Plan resource name.')
param functionAppPlanName string

@allowed([
  'EP1'
  'EP2'
  'EP3'
])
param functionAppPlanSku string
param isLinux bool
param tags object

resource plan 'Microsoft.Web/serverfarms@2021-01-15' = {
  location: location
  name: functionAppPlanName
  sku: {
    name: functionAppPlanSku
    tier: 'ElasticPremium'          // 'ElasticPremium' Required for Premium Functions
    size: functionAppPlanSku
    family: 'EP'                    // 'EP' Required for Premium Functions
  }
  kind: 'elastic'
  tags: tags
  properties: {
    maximumElasticWorkerCount: 20
    reserved: isLinux
  }
}
