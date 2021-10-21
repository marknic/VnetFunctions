@description('Resource ID of the network interface (NIC) resource')
param nicId string

// Extract the name from the end of the ID
var nicName = substring(nicId, lastIndexOf(nicId, '/') + 1)

resource privateEndpointNic 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
  name: nicName
}

output nicProps object = privateEndpointNic.properties
