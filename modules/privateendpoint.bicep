param privateEndpointName string
param vnetName string
param subnetName string
param serviceId string
param tags object

@allowed([
  'file'
  'table'
  'blob'
  'queue'
  'sites'
])
param groupId string

// -- Private Endpoints --
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointName
  location: resourceGroup().location
  tags: tags
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageFilePrivateLinkConnection'
        properties: {
          privateLinkServiceId: serviceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

output privateEndpointIp object = privateEndpoint.properties.networkInterfaces[0]
