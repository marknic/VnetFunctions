param nicName string

resource privateEndpointNic 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
  name: nicName
}

output nicProps object = privateEndpointNic.properties
