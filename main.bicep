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
param subscriptionId string

@description('Resource Group Name')
param resourceGroupName string

@allowed([
  'Dev'
  'Test'
  'Perf'
  'NonProd'
  'Prod'
])
param appEnvironment string

param location string = resourceGroup().location

param functionSubnetName string

var dashName = toLower('${appEnvironment}-${prefix}-${appName}-${suffix}')
var nodashName = toLower('${appEnvironment}${prefix}${appName}${suffix}')

//var keyvaultName = '${nodashName}kv'

var storageAccountName = '${nodashName}sa'
var storageAccountNameTmp = '${nodashName}satmp'

var appServicePlanName = '${dashName}-asp'
var functionAppName = '${nodashName}fa'
var appInsightsName = '${nodashName}-ai'

var fileShareSuffix = substring(uniqueString(subscription().id), 0, 4)
var fileShareName = '${nodashName}fa${fileShareSuffix}'

var vnetName = '${dashName}-vnet'
param vnetAddress string = '10.4'
param vnetMask string = '16'

param isLinux bool = false

param subnets array

param deployDate object = {
  'DeployDate': utcNow('d')
}

param tags object = union(resourceTags, deployDate)

module vnet01 '01vnet.bicep' = {
  name: 'vnet1'
  params: {
    vnetName: vnetName
    tags: tags
    subnets: subnets
    vnetAddress: vnetAddress
    vnetMask: vnetMask
  }
}

module privatezone01 '02privatezones.bicep' = {
  name: 'zones'
  params: {
    tags: tags
  }
}

module zoneLink1 '03privatelinks.bicep' = {
  name: 'zonelinks'
  params: {
    tags: tags
    storageAccountName: storageAccountName
    virtualNetworkId: vnet01.outputs.vnetId
    zoneNameBlob: privatezone01.outputs.blobZoneName
    zoneNameFile: privatezone01.outputs.fileZoneName
  }
}

module privateEndpoint1 '04privateEndpoints.bicep' = {
  name: 'endpoints'
  params: {
    tags: tags
    storageAccountId: storage01.outputs.id
    storageAccountName: storageAccountName
    subnetName: 'sn-util-2-0-24'
    vnetName: vnetName
  }
}

module dnsZoneGroup1 '05privateEndpointZoneGroups.bicep' = {
  name: 'zoneGroups'
  params: {
    blobZoneId: privatezone01.outputs.blobZoneId
    fileZoneId: privatezone01.outputs.fileZoneId
    storageAccountName: storageAccountName
    privateEndpointStorageBlobName: privateEndpoint1.outputs.privateEndpointBlobName
    privateEndpointStorageFileName: privateEndpoint1.outputs.privateEndpointFileName
  }
}

module storageTmp 'modules/basicstorageaccount.bicep' = {
  name: 'storenametmp'
  params: {
    location: location
    storageAccountName: storageAccountNameTmp
    storageAccountSku: 'Standard_LRS'
    kind: 'StorageV2'
    tags: tags
  }
}

module fileShareTmp 'modules/storageaccountfileshare.bicep' = {
  name: 'filesharetmp'
  params: {
    fileShareName: fileShareName
    storageAccountName: storageAccountNameTmp
  }
  dependsOn: [
    storageTmp
  ]
}

module appInsights01 'modules/appinsights.bicep' = {
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

module premFunc 'modules/premiumfunctionapp.bicep' = {
  name: 'premFunc01'
  params: {
    appInsightsName: appInsightsName
    appServicePlanName: appServicePlanName
    functionAppName: functionAppName
    isLinux: isLinux
    location: resourceGroup().location
    storageAccountName: storageAccountNameTmp
    functionContentShareName: fileShareName
    subnetName: functionSubnetName
    tags: tags
    vnetName: vnetName
    functionAppScaleLimit: 10
    minimumElasticInstanceCount: 3
    identityType: 'SystemAssigned'
    runtime: 'dotnet/3.1'
  }
  dependsOn: [
    appServicePlan
    appInsights01
    storageTmp
    fileShareTmp
  ]
}

module storage01 'modules/storageaccount_rbac.bicep' = {
  name: 'funcstore'
  params: {
    subscriptionId: subscriptionId
    location: location
    storageAccountName: storageAccountName
    storageAccountSku: 'Standard_ZRS'
    kind: 'StorageV2'
    tags: tags
    principalId: premFunc.outputs.managedIdentity
  }
  dependsOn: [
    premFunc
  ]
}

module privateEndpoint2 '07privateEndpointsFunction.bicep' = {
  name: 'funcEndpoints'
  params: {
    tags: tags
    functionAppName: functionAppName
    functionAppId: premFunc.outputs.functionAppId
    subnetName: 'sn-util-2-0-24'
    vnetName: vnetName
  }
}

module fileShare01 'modules/storageaccountfileshare.bicep' = {
  name: 'fileshare'
  params: {
    fileShareName: fileShareName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    storage01
  ]
}

output subscriptionId string = subscriptionId
output location string = location
output fileShareName string = fileShareName
output functionAppName string = functionAppName
output backingStoreFileShareName string = fileShareName
output backingStoreTmpAccountName string = storageAccountNameTmp
output backingStoreAccountName string = storageAccountName
output resourceGroupName string = resourceGroupName
