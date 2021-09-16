param privateEndpointName string
param dnsZoneGroupName string
param dnsZoneId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' existing = {
  name: privateEndpointName
}

// -- Private DNS Zone Groups --
resource storageFilePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: privateEndpoint
  name: dnsZoneGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: dnsZoneId
        }
      }
    ]
  }
}
