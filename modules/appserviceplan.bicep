
@description('App Service Plan resource location.')
param location string

@description('App Service Plan resource name.')
param functionAppPlanName string

param functionAppPlanSku string
param isReserved bool
param tags object

resource plan 'Microsoft.Web/serverfarms@2021-01-01' = {
  location: location
  name: functionAppPlanName
  sku: {
    name: functionAppPlanSku
    tier: 'ElasticPremium'
    size: functionAppPlanSku
    family: 'EP'
  }
  kind: 'elastic'
  tags: tags
  properties: {
    maximumElasticWorkerCount: 20
    reserved: isReserved
  }
}
