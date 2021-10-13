@description('The name of the Function App.')
param functionAppName string

@description('Region (datacenter) where this resource is to be deployed')
param location string

@description('Set to true is the Function App OS is Linux.')
param isLinux bool

@description('Does this Function App use Containers: true if it does.')
param useContainers bool = false

@description('Resource tags for this Function App.')
param tags object

@description('The name of the App Service Plan for this Function App.')
param appServicePlanName string

@description('Application Insights instance to be used with the Function App.')
param appInsightsName string

@description('Name of the backing storage account used by the Function App.')
param storageAccountName string

@description('Name of the VNET the Function App should be added to for (VNET Integration).')
param vnetName string

@description('Name of the subnet the Function App should be added to for (VNET Integration).')
param subnetName string

@description('Set to false to utilize a 64-bit process.  Default is true (32-bit process).')
param use32BitWorkerProcess bool = true

@allowed([
  'dotnet/3.1'
  'java/8'
  'java/11'
  'node/12'
  'node/14'
])
@description('The runtime (language) and version for this Function App.')
param runtime string = 'dotnet/3.1'

// Scaling
@description('The number of instances that are always ready and warm for this function app.')
@minValue(3)
param minimumElasticInstanceCount int = 3

param functionAppScaleLimit int = 20

// Variables
var runtimeSplit = split(runtime, '/')
var workerRuntime = runtimeSplit[0]

param functionContentShareName string

var linuxOS = useContainers ? true : isLinux

@allowed([
  'None'
  'SystemAssigned'
  'SystemAssigned, UserAssigned'
  'UserAssigned'
])
param identityType string = 'SystemAssigned'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: vnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageAccountName
}

resource appInsightsComponents 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' existing = {
  name: appServicePlanName
}

resource functionApp 'Microsoft.Web/sites@2021-01-01' = {
  name: functionAppName
  location: location
  tags: tags
  identity: {
    type: identityType
  }
  kind: linuxOS ? 'functionapp,linux' : 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    reserved: linuxOS
    httpsOnly: true
    clientAffinityEnabled: false
    virtualNetworkSubnetId: '${virtualNetwork.id}/subnets/${subnetName}'
    siteConfig: {
      minimumElasticInstanceCount: minimumElasticInstanceCount
      functionAppScaleLimit: functionAppScaleLimit
      vnetName: vnetName
      loadBalancing: 'LeastRequests'
      ftpsState: 'FtpsOnly'
      vnetRouteAllEnabled: true
      use32BitWorkerProcess: use32BitWorkerProcess
    }
  }
  dependsOn: [
    appServicePlan
    appInsightsComponents
    storageAccount
  ]
}

resource appSettings 'Microsoft.Web/sites/config@2021-01-01' = {
  name: 'appsettings'
  parent: functionApp
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsComponents.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsComponents.properties.ConnectionString
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
    WEBSITE_CONTENTSHARE: functionContentShareName
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: workerRuntime
    //WEBSITE_VNET_ROUTE_ALL: '1'
    //WEBSITE_CONTENTOVERVNET: '1'
    //WEBSITE_DNS_SERVER: '168.63.129.16'
  }
}

// resource functionSlot 'Microsoft.Web/sites/slots@2020-12-01' = {
//   parent: functionApp
//   name: 'Staging'
//   kind: 'app'
//   location: location
// }

resource planNetworkConfig 'Microsoft.Web/sites/networkConfig@2021-01-01' = {
  parent: functionApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    swiftSupported: true
  }
}


output managedIdentity string = functionApp.identity.principalId
output functionAppId string = functionApp.id
