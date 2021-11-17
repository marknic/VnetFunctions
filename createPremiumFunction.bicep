@description('Common tags object for all resources')
param resourceTags object

// Standarized naming convention values
@description('Standard naming convention prefix')
@minLength(2)
@maxLength(4)
param prefix string

@description('Standard naming convention suffix/number')
@minLength(2)
@maxLength(6)
param suffix string

@description('Standard naming convention application name/abbreviation')
@minLength(3)
@maxLength(12)
param appName string

@description('Subscription ID (GUID)')
param subscriptionId string = subscription().subscriptionId

@description('Resource Group Name')
param resourceGroupName string = resourceGroup().name

@allowed([
  'Dev'
  'Test'
  'Perf'
  'NonProd'
  'Prod'
])
param appEnvironment string

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

param functionAppScaleLimit int = 10
param minimumElasticInstanceCount int = 3

param functionSubnetName string

param isLinux bool = false

param deployDate object = {
  'DeployDate': utcNow('d')
}

param tags object = union(resourceTags, deployDate)

//
// Variables
//

var dashName = toLower('${appEnvironment}-${prefix}-${appName}-${suffix}')
var nodashName = toLower('${appEnvironment}${prefix}${appName}${suffix}')

var storageAccountName = '${nodashName}sa'

var appServicePlanName = '${dashName}-asp'
var functionAppName = '${nodashName}fa'
var appInsightsName = '${nodashName}-ai'

var fileShareSuffix = substring(uniqueString(subscription().id), 0, 4)
var fileShareName = '${nodashName}fa${fileShareSuffix}'

var vnetName = '${dashName}-vnet'

module secureBackingStore 'modules/storageaccount.bicep' = {
  name: 'funcstore'
  params: {
    location: location
    storageAccountName: storageAccountName
    storageAccountSku: 'Standard_ZRS'
    kind: 'StorageV2'
    tags: tags
  }
}

module fileShareInSecureBackingStore 'modules/storageaccountfileshare.bicep' = {
  name: 'fileshare'
  params: {
    fileShareName: fileShareName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    secureBackingStore
  ]
}

module appInsightsForFunction 'modules/appinsights.bicep' = {
  name: 'ai'
  params: {
    applicationInsightsName: appInsightsName
    location: resourceGroup().location
  }
}

module appServicePlan 'modules/appserviceplan.bicep' = {
  name: 'funcAppServicePlan'
  params: {
    functionAppPlanName: appServicePlanName
    functionAppPlanSku: 'EP3'
    isLinux: false
    location: resourceGroup().location
    tags: tags
  }
}

module premiumFunction 'modules/premiumfunctionapp.bicep' = {
  name: 'premFunc01'
  params: {
    appInsightsName: appInsightsName
    appServicePlanName: appServicePlanName
    functionAppName: functionAppName
    isLinux: isLinux
    location: resourceGroup().location
    storageAccountName: storageAccountName
    functionContentShareName: fileShareName
    subnetName: functionSubnetName
    tags: tags
    vnetName: vnetName
    functionAppScaleLimit: functionAppScaleLimit
    minimumElasticInstanceCount: minimumElasticInstanceCount
    identityType: 'SystemAssigned'
    runtime: 'dotnet/3.1'
  }
  dependsOn: [
    secureBackingStore
    fileShareInSecureBackingStore
    appServicePlan
    appInsightsForFunction
  ]
}

output subscriptionId string = subscriptionId
output location string = location
output fileShareName string = fileShareName
output functionAppName string = functionAppName
output backingStoreFileShareName string = fileShareName
output backingStoreAccountName string = storageAccountName
output resourceGroupName string = resourceGroupName
