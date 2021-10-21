@description('The name of the resource the private endpoint is being created for.')
param privateResourceName string

@description('The Azure resource ID for the resource being secured.')
param resourceId string

@description('Name of the subnet that holds the IP address for the private endpoint.')
param subnetName string

@description('Name of the VNET that holds the IP address for the private endpoint.')
param vnetName string

@description('list of standard resource tags')
param tags object

@description('The type of private endpoint zone being created.')
@allowed([
  'blob'
  'file'
  'sites'
])
param groupId string

@description('Zone ID created for this Private Endpoint.')
param zoneId string

var privateEndpointName = '${privateResourceName}-${groupId}-private-endpoint'
var privateEndpointResName = '${privateResourceName}ep'

module endpoint 'modules/privateendpoint.bicep' = {
  name: privateEndpointResName
  params: {
    groupId: groupId
    privateEndpointName: privateEndpointName
    serviceId: resourceId
    subnetName: subnetName
    tags: tags
    vnetName: vnetName
  }
}

var zoneResName = 'zoneGroup${groupId}'

module privateEndpointZoneGroup 'modules/dnsZoneGroup.bicep' = {
  name: zoneResName
  params: {
    dnsZoneGroupName: 'blobPrivateDnsZoneGroup'
    dnsZoneId: zoneId
    privateEndpointName: privateEndpointName
  }
}

output privateEndpointName string = privateEndpointName
