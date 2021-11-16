

param tags object
param virtualNetworkId string

@description('The name of the resource the private endpoint is being created for.')
param privateResourceName string

@allowed([
  'blob'
  'file'
  'sites'
])
param zoneType string

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
      id: virtualNetworkId
    }
  }
  tags: tags
}


output privateDnsZoneName string = privateDnsZoneName
output privateZoneLinkName string = privateZoneLinkName
output privateZoneId string = dnsZone.id
output privateDnsZone object = dnsZone
