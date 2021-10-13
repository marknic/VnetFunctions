param storageAccountName string
param storageAccountId string
param subnetName string
param vnetName string
param tags object

var privateEndpointStorageBlobName = '${storageAccountName}-blob-private-endpoint'
var privateEndpointStorageFileName = '${storageAccountName}-file-private-endpoint'

module endpoint1 'modules/privateendpoint.bicep' = {
  name: 'ep1'
  params: {
    groupId: 'blob'
    privateEndpointName: privateEndpointStorageBlobName
    serviceId: storageAccountId
    subnetName: subnetName
    tags: tags
    vnetName: vnetName
  }
}

module endpoint2 'modules/privateendpoint.bicep' = {
  name: 'ep2'
  params: {
    groupId: 'file'
    privateEndpointName: privateEndpointStorageFileName
    serviceId: storageAccountId
    subnetName: subnetName
    tags: tags
    vnetName: vnetName
  }
}

output privateEndpointBlobName string = privateEndpointStorageBlobName
output privateEndpointFileName string = privateEndpointStorageFileName
