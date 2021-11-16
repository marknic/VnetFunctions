// This module takes the name of a private endpoint and returns the IP address of the network interface
@description('The name of the private endpoint from which to get the IP address')
param endpointName string

// Get the existing private endpoint information
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' existing = {
  name: endpointName
}

// Grab the ID of the network interface (NIC) used by the private endpoint
var nicId = first(privateEndpoint.properties.networkInterfaces).id

// Go get the information from the NIC
module nicInfo 'networkInterfaceProperties.bicep' = {
  name: 'nicInfo'
  params: {
    nicId: nicId
  }
}

// Return with the IP address
output nicIp string = first(nicInfo.outputs.nicProps.ipConfigurations).properties.privateIPAddress
output nicName string = substring(nicId, lastIndexOf(nicId, '/') + 1)
