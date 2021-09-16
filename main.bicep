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


@allowed([
  'Dev'
  'Test'
  'Perf'
  'NonProd'
  'Prod'
])
param appEnvironment string

param location string = resourceGroup().location

var dashName = '${appEnvironment}-${prefix}-${appName}-${suffix}'
var nodashName = toLower('${appEnvironment}${prefix}${appName}${suffix}')

//var keyvaultName = '${nodashName}kv'

var storageAccountName = '${nodashName}sa'

//var appServicePlanName = '${dashName}-asp'
var functionAppName = '${nodashName}fa'
var appInsightsName = '${nodashName}-ai'

var vnetName = '${dashName}-vnet'
param vnetAddress string = '10.4'
param vnetMask string = '16'

param subnets array
//  = [
//   {
//     name: 'sn-util-0-0-24'
//     properties: {
//       addressPrefix: '${vnetAddress}.0.0/24'
//     }
//   }
//   {
//     name: 'sn-util-1-0-24'
//     properties: {
//       addressPrefix: '${vnetAddress}.1.0/24'
//     }
//   }
//   {
//     name: 'sn-util-2-0-24'
//     properties: {
//       addressPrefix: '${vnetAddress}.2.0/24'
//       privateLinkServiceNetworkPolicies: 'Disabled'
//       privateEndpointNetworkPolicies: 'Disabled'
//     }
//   }
//   {
//     name: 'sn-func-3-0-27-d'
//     properties: {
//       addressPrefix: '${vnetAddress}.3.0/27'
//       delegations: [
//         {
//           name: 'delegation'
//           properties: {
//             serviceName: 'Microsoft.Web/serverFarms'
//           }
//         }
//       ]
//     }
//   }
// ]

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

module storage01 'modules/storageaccount.bicep' = {
  name: 'storename'
  params: {
    location: location
    storageAccountName: storageAccountName
    storageAccountSku: 'Standard_LRS'
    kind: 'StorageV2'
    tags: tags
  }
}

module fileShare01 'modules/storageaccountfileshare.bicep' = {
  name: 'fileshare'
  params: {
    fileShareName: functionAppName
    storageAccountName: storageAccountName
  }
}

module appInsights01 'modules/appinsights.bicep' = {
  name: 'ai'
  params: {
    applicationInsightsName: appInsightsName
    location: resourceGroup().location
  }
}
