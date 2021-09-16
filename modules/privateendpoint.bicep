param privateEndpointName string
param vnetName string
param subnetName string
param storageAccountId string
param tags object

@allowed([
  'file'
  'table'
  'blob'
  'queue'
])
param groupId string

// -- Private Endpoints --
resource storageFilePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
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
          privateLinkServiceId: storageAccountId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}
