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

//param functionSubnetName string

param storagePrivateEndpointSubnet string = 'sn-pep-2-0-24'
param functionPrivateEndpointSubnet string = 'sn-pep-2-0-24'

var dashName = toLower('${appEnvironment}-${prefix}-${appName}-${suffix}')
var nodashName = toLower('${appEnvironment}${prefix}${appName}${suffix}')

//var keyvaultName = '${nodashName}kv'

var storageAccountName = '${nodashName}sa'
var storageAccountNameTmp = '${nodashName}satmp'

//var appServicePlanName = '${dashName}-asp'
var functionAppName = '${nodashName}fa'
//var appInsightsName = '${nodashName}-ai'

var fileShareSuffix = substring(uniqueString(subscription().id), 0, 4)
var fileShareName = '${nodashName}fa${fileShareSuffix}'

var vnetName = '${dashName}-vnet'

// param vnetAddress string = '10.4'
// param vnetMask string = '16'

// param isLinux bool = false

// param subnets array

param deployDate object = {
  'DeployDate': utcNow('d')
}

param tags object = union(resourceTags, deployDate)


// module parentVnet '01vnet.bicep' = {
//   name: 'applictionVnet'
//   params: {
//     vnetName: vnetName
//     tags: tags
//     subnets: subnets
//     vnetAddress: vnetAddress
//     vnetMask: vnetMask
//   }
// }

// module jumpServer '02bastion.bicep' = {
//   name: 'bastionConnect'
//   params: {
//     bastionSubnetId: parentVnet.outputs.AzureBastionSubnetId
//     vmSubnetId: parentVnet.outputs.VmSubnetId
//   }
//   dependsOn: [
//     parentVnet
//   ]
// }

// // Backing Store Creation - Temporary
// module temporaryStorageAccount 'modules/basicstorageaccount.bicep' = {
//   name: 'storenametmp'
//   params: {
//     location: location
//     storageAccountName: storageAccountNameTmp
//     storageAccountSku: 'Standard_LRS'
//     kind: 'StorageV2'
//     tags: tags
//   }
// }

// // Backing Store Creation -
// module fileShareInTempStorage 'modules/storageaccountfileshare.bicep' = {
//   name: 'filesharetmp'
//   params: {
//     fileShareName: fileShareName
//     storageAccountName: storageAccountNameTmp
//   }
//   dependsOn: [
//     temporaryStorageAccount
//   ]
// }

// module appInsightsForFunction 'modules/appinsights.bicep' = {
//   name: 'ai'
//   params: {
//     applicationInsightsName: appInsightsName
//     location: resourceGroup().location
//   }
// }

// module appServicePlan 'modules/appserviceplan.bicep' = {
//   name: 'funcAppServicePlan'
//   params: {
//     functionAppPlanName: appServicePlanName
//     functionAppPlanSku: 'EP3'
//     isLinux: false
//     location: resourceGroup().location
//     tags: tags
//   }
// }

// module premiumFunction 'modules/premiumfunctionapp.bicep' = {
//   name: 'premFunc01'
//   params: {
//     appInsightsName: appInsightsName
//     appServicePlanName: appServicePlanName
//     functionAppName: functionAppName
//     isLinux: isLinux
//     location: resourceGroup().location
//     storageAccountName: storageAccountNameTmp
//     functionContentShareName: fileShareName
//     subnetName: functionSubnetName
//     tags: tags
//     vnetName: vnetName
//     functionAppScaleLimit: 10
//     minimumElasticInstanceCount: 3
//     identityType: 'SystemAssigned'
//     runtime: 'dotnet/3.1'
//   }
//   dependsOn: [
//     appServicePlan
//     appInsightsForFunction
//     temporaryStorageAccount
//     fileShareInTempStorage
//   ]
// }

// module secureBackingStore 'modules/storageaccount_rbac.bicep' = {
//   name: 'funcstore'
//   params: {
//     subscriptionId: subscriptionId
//     location: location
//     storageAccountName: storageAccountName
//     storageAccountSku: 'Standard_ZRS'
//     kind: 'StorageV2'
//     tags: tags
//     principalId: premiumFunction.outputs.managedIdentity
//   }
//   dependsOn: [
//     premiumFunction
//   ]
// }

// module fileShareInSecureBackingStore 'modules/storageaccountfileshare.bicep' = {
//   name: 'fileshare'
//   params: {
//     fileShareName: fileShareName
//     storageAccountName: storageAccountName
//   }
//   dependsOn: [
//     secureBackingStore
//   ]
// }


// Copy Files

// Get the required resources for the rest of the deployment

resource parentVnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: vnetName
}


resource secureBackingStore 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

resource premiumFunction 'Microsoft.Web/sites@2021-02-01' existing = {
  name: functionAppName
}


module privateDnsZoneAndLinkBlob '03privateZones.bicep' = {
  name: 'privateBlob'
  params: {
    privateResourceName: storageAccountName
    tags: tags
    virtualNetworkId: parentVnet.id
    zoneType: 'blob'
  }
}

module privateDnsZoneAndLinkFile '03privateZones.bicep' = {
  name: 'privateFile'
  params: {
    privateResourceName: storageAccountName
    tags: tags
    virtualNetworkId: parentVnet.id
    zoneType: 'file'
  }
}

module privateDnsZoneAndLinkFunction '03privateZones.bicep' = {
  name: 'privateFunction'
  params: {
    privateResourceName: functionAppName
    tags: tags
    virtualNetworkId: parentVnet.id
    zoneType: 'sites'
  }
}

module privateEndpointZoneBlob '04privateEndpoint.bicep' = {
  name: 'blobPrivateEndpoint'
  params: {
    groupId: 'blob'
    privateResourceName: storageAccountName
    resourceId: secureBackingStore.id
    subnetName: storagePrivateEndpointSubnet
    tags: tags
    vnetName: vnetName
    zoneId: privateDnsZoneAndLinkBlob.outputs.privateZoneId
  }
  dependsOn: [
    privateDnsZoneAndLinkBlob
  ]
}

module privateEndpointZoneFile '04privateEndpoint.bicep' = {
  name: 'filePrivateEndpoint'
  params: {
    groupId: 'file'
    privateResourceName: storageAccountName
    resourceId: secureBackingStore.id
    subnetName: storagePrivateEndpointSubnet
    tags: tags
    vnetName: vnetName
    zoneId: privateDnsZoneAndLinkFile.outputs.privateZoneId
  }
  dependsOn: [
    privateDnsZoneAndLinkFile
    privateEndpointZoneBlob
  ]
}

module privateEndpointZoneSites '04privateEndpoint.bicep' = {
  name: 'sitesPrivateEndpoint'
  params: {
    groupId: 'sites'
    privateResourceName: functionAppName
    resourceId: premiumFunction.id
    subnetName: functionPrivateEndpointSubnet
    tags: tags
    vnetName: vnetName
    zoneId: privateDnsZoneAndLinkFunction.outputs.privateZoneId
  }
  dependsOn: [
    privateDnsZoneAndLinkFunction
  ]
}

module functionEndpointIp 'modules/data/privateEndpointIp.bicep' = {
  name: 'getFunctionEpIp'
  params: {
    endpointName: privateEndpointZoneSites.outputs.privateEndpointName
  }
  dependsOn: [
    privateEndpointZoneSites
  ]
}

module dnsZoneFuncSettings 'modules/privateDnsZoneSettings.bicep' = {
  name: 'privateDnsZoneSettings'
  params: {
    privateZoneNameSites: 'privatelink.azurewebsites.net'
    privateSiteName: functionAppName
    ipAddressSites: functionEndpointIp.outputs.nicIp

    privateZoneNameBlob: 'privatelink.blob.${environment().suffixes.storage}'
    privateZoneNameFile: 'privatelink.file.${environment().suffixes.storage}'
    privateStorageName: storageAccountName

    ipAddressBlob: privateEndpointZoneBlob.outputs.nicIp
    ipAddressFile: privateEndpointZoneFile.outputs.nicIp
  }
  dependsOn: [
    privateEndpointZoneSites
    privateDnsZoneAndLinkFunction
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
