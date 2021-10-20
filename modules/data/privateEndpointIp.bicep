// This module takes the name of a private endpoint and returns the IP address of the network interface

param endpointName string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' existing = {
  name: endpointName
}

var nicId = first(privateEndpoint.properties.networkInterfaces).id

var nicName = substring(nicId, lastIndexOf(nicId, '/') + 1)

module nicInfo 'networkInterfaceIp.bicep' = {
  name: 'nicInfoTest'
  params: {
    nicName: nicName
  }
}

output nicIp string = first(nicInfo.outputs.nicProps.ipConfigurations).properties.privateIPAddress
