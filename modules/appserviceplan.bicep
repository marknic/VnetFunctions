
@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@description('App Service Plan resource name.')
param functionAppPlanName string

@description('Which Compute SKU to use?')
@allowed([
  'EP1'
  'EP2'
  'EP3'
])
param functionAppPlanSku string

@description('Is this a Linux compute resource?')
param isLinux bool

@description('list of standard resource tags')
param tags object = {}

//
// Resources
//

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
