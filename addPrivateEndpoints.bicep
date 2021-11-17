
@description('Name of the function to be given a private endpoint (just the unique name, without the domain.)')
param functionAppName string

@description('Name of the storage account to be given private endpoints (just the unique name, without the domain.)')
param storageAccountName string

@description('Name of the VNET where the private endpoints will be created.')
param vnetName string

@description('Name of the subnet where the function app private endpoint will reside.')
param functionPrivateEndpointSubnetName string

@description('Name of the subnet where the storage account private endpoints will reside.')
param storagePrivateEndpointSubnetName string

@description('list of standard resource tags.')
param tags object = {}

param subscriptionId string = subscription().subscriptionId
param resourceGroupName string = resourceGroup().name

//
// Variables
//

var idBase = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers'
var storageAccountId = '${idBase}/Microsoft.Storage/storageAccounts/${storageAccountName}'
//var vnetId = '${idBase}/Microsoft.Network/virtualNetworks/${vnetName}'
var functionAppId = '${idBase}/Microsoft.Web/sites/${functionAppName}'

//
// Resources
//

module privateDnsZoneAndLinkBlob '03privateZones.bicep' = {
  name: 'privateBlob'
  params: {
    privateResourceName: storageAccountName
    tags: tags
    vnetName: vnetName
    zoneType: 'blob'
  }
}

module privateDnsZoneAndLinkFile '03privateZones.bicep' = {
  name: 'privateFile'
  params: {
    privateResourceName: storageAccountName
    tags: tags
    vnetName: vnetName
    zoneType: 'file'
  }
}

module privateDnsZoneAndLinkFunction '03privateZones.bicep' = {
  name: 'privateFunction'
  params: {
    privateResourceName: functionAppName
    tags: tags
    vnetName: vnetName
    zoneType: 'sites'
  }
}

module privateEndpointZoneBlob '04privateEndpoint.bicep' = {
  name: 'blobPrivateEndpoint'
  params: {
    groupId: 'blob'
    privateResourceName: storageAccountName
    resourceId: storageAccountId
    subnetName: storagePrivateEndpointSubnetName
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
    resourceId: storageAccountId
    subnetName: storagePrivateEndpointSubnetName
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
    resourceId: functionAppId
    subnetName: functionPrivateEndpointSubnetName
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
