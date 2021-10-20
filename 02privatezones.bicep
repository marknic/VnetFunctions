

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

var zoneResName = 'zone${zoneType}'
var linkResName = '${zoneResName}link'

// -- Private DNS Zones --
module dnsZone 'modules/dnsZone.bicep' = {
  name: zoneResName
  params: {
    zoneName: privateDnsZoneName
    tags: tags
  }
}


module zonelink 'modules/dnsZoneLink.bicep' = {
  name: linkResName
  params: {
    tags: tags
    vnetId: virtualNetworkId
    linkName: privateZoneLinkName
    zoneName: privateDnsZoneName
  }
}

output privateDnsZoneName string = privateDnsZoneName
output privateZoneLinkName string = privateZoneLinkName
output privateZoneId string = dnsZone.outputs.zoneId
