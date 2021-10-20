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

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

param functionSubnetName string

param storagePrivateEndpointSubnet string = 'sn-pep-2-0-24'
param functionPrivateEndpointSubnet string = 'sn-pep-2-0-24'

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

var privateLinkFuncName = 'privatelink.azurewebsites.net/${functionAppName}.scm'

param vnetAddress string = '10.4'
param vnetMask string = '16'

param isLinux bool = false

param subnets array

param deployDate object = {
  'DeployDate': utcNow('d')
}

param tags object = union(resourceTags, deployDate)

module parentVnet '01vnet.bicep' = {
  name: 'vnet1'
  params: {
    vnetName: vnetName
    tags: tags
    subnets: subnets
    vnetAddress: vnetAddress
    vnetMask: vnetMask
  }
}

module jumpServer '07bastion.bicep' = {
  name: 'bastionConnect'
  params: {
    bastionSubnetId: parentVnet.outputs.AzureBastionSubnetId
    vmSubnetId: parentVnet.outputs.VmSubnetId
  }
  dependsOn: [
    parentVnet
  ]
}


// Backing Store Creation - Temporary
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

// Backing Store Creation -
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

module privateZoneBlob '02privateZones.bicep' = {
  name: 'privateBlob'
  params: {
    privateResourceName: storageAccountName
    tags: tags
    virtualNetworkId: parentVnet.outputs.vnetId
    zoneType: 'blob'
  }
}

module privateZoneFile '02privateZones.bicep' = {
  name: 'privateFile'
  params: {
    privateResourceName: storageAccountName
    tags: tags
    virtualNetworkId: parentVnet.outputs.vnetId
    zoneType: 'file'
  }
}

module privateZoneFunction '02privateZones.bicep' = {
  name: 'privateFunction'
  params: {
    privateResourceName: functionAppName
    tags: tags
    virtualNetworkId: parentVnet.outputs.vnetId
    zoneType: 'sites'
  }
}

module privateEndpointZoneBlob '03privateEndpoint.bicep' = {
  name: 'blobPrivateEndpoint'
  params: {
    groupId: 'blob'
    privateResourceName: storageAccountName
    resourceId: storage01.outputs.id
    subnetName: storagePrivateEndpointSubnet
    tags: tags
    vnetName: vnetName
    zoneId: privateZoneBlob.outputs.privateZoneId
  }
  dependsOn: [
    privateZoneBlob
  ]
}

module privateEndpointZoneFile '03privateEndpoint.bicep' = {
  name: 'filePrivateEndpoint'
  params: {
    groupId: 'file'
    privateResourceName: storageAccountName
    resourceId: storage01.outputs.id
    subnetName: storagePrivateEndpointSubnet
    tags: tags
    vnetName: vnetName
    zoneId: privateZoneFile.outputs.privateZoneId
  }
  dependsOn: [
    privateZoneFile
  ]
}

module privateEndpointZoneSites '03privateEndpoint.bicep' = {
  name: 'sitesPrivateEndpoint'
  params: {
    groupId: 'sites'
    privateResourceName: functionAppName
    resourceId: premFunc.outputs.functionAppId
    subnetName: functionPrivateEndpointSubnet
    tags: tags
    vnetName: vnetName
    zoneId: privateZoneFunction.outputs.privateZoneId
  }
  dependsOn: [
    privateZoneFunction
  ]
}

module functionEndpointIp 'modules/data/privateEndpointIp.bicep' = {
  name: 'getFunctionEpIp'
  params: {
    endpointName: privateEndpointZoneSites.outputs.privateEndpointName
  }
}


resource dnsZoneFunc 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: privateLinkFuncName
  parent: privateZoneFunction
  properties: {
    metadata: {
      creator: 'Created via Bicep template'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: functionEndpointIp.outputs.nicIp
      }
    ]
  }
}

resource dnsZoneScm 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privateLinkFuncName}.scm'
  parent: privateZoneFunction
  properties: {
    metadata: {
      creator: 'Created via Bicep template'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: functionEndpointIp.outputs.nicIp
      }
    ]
  }
}

resource dnsZoneSoa 'Microsoft.Network/privateDnsZones/SOA@2020-06-01' = {
  name: 'privatelink.azurewebsites.net/@'
  parent: privateZoneFunction
}

output subscriptionId string = subscriptionId
output location string = location
output fileShareName string = fileShareName
output functionAppName string = functionAppName
output backingStoreFileShareName string = fileShareName
output backingStoreTmpAccountName string = storageAccountNameTmp
output backingStoreAccountName string = storageAccountName
output resourceGroupName string = resourceGroupName
