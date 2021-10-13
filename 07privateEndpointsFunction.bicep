param functionAppName string
param functionAppId string
param subnetName string
param vnetName string
param tags object

var privateEndpointFunctionApp = '${functionAppName}-function-private-endpoint'

module endpoint3 'modules/privateendpoint.bicep' = {
  name: 'ep3'
  params: {
    groupId: 'function'
    privateEndpointName: privateEndpointFunctionApp
    serviceId: functionAppId
    subnetName: subnetName
    tags: tags
    vnetName: vnetName
  }
}

output privateEndpointFunctionApp string = privateEndpointFunctionApp
