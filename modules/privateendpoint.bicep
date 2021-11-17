param privateEndpointName string
param vnetName string
param subnetName string
param serviceId string

@allowed([
  'file'
  'table'
  'blob'
  'queue'
  'sites'
])
param groupId string

@description('list of standard resource tags')
param tags object = {}

//
// Resources
//

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

output netInterface object = first(privateEndpoint.properties.networkInterfaces)
