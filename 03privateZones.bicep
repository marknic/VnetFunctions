

@description('list of standard resource tags.')
param tags object = {}

@description('Name of the VNET.')
param vnetName string

@description('The name of the resource the private endpoint is being created for.')
param privateResourceName string

@allowed([
  'blob'
  'file'
  'sites'
])
param zoneType string

//
// Variables
//


var subscriptionId = subscription().subscriptionId
var resourceGroupName = resourceGroup().name

var idBase = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers'
var vnetId = '${idBase}/Microsoft.Network/virtualNetworks/${vnetName}'

var privateDnsZoneName = zoneType == 'blob' ? 'privatelink.blob.${environment().suffixes.storage}' : zoneType == 'file' ? 'privatelink.file.${environment().suffixes.storage}' : 'privatelink.azurewebsites.net'
var privateZoneLinkName = '${privateResourceName}-${zoneType}-link'



// -- Private DNS Zones --
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}


resource storageFileDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZone
  name: privateZoneLinkName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  tags: tags
}

output privateDnsZoneName string = privateDnsZoneName
output privateZoneLinkName string = privateZoneLinkName
output privateZoneId string = dnsZone.id
output privateDnsZone object = dnsZone
