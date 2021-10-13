param blobZoneId string
param fileZoneId string
param storageAccountName string

param privateEndpointStorageBlobName string = '${storageAccountName}-blob-private-endpoint'
param privateEndpointStorageFileName string = '${storageAccountName}-file-private-endpoint'

module privateEndpointZoneGroup1 'modules/dnsZoneGroup.bicep' = {
  name: 'zoneGroup1'
  params: {
    dnsZoneGroupName: 'blobPrivateDnsZoneGroup'
    dnsZoneId: blobZoneId
    privateEndpointName: privateEndpointStorageBlobName
  }
}

module privateEndpointZoneGroup2 'modules/dnsZoneGroup.bicep' = {
  name: 'zoneGroup2'
  params: {
    dnsZoneGroupName: 'filePrivateDnsZoneGroup'
    dnsZoneId: fileZoneId
    privateEndpointName: privateEndpointStorageFileName
  }
}

