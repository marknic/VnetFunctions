param tags object

var privateStorageBlobDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var privateStorageFileDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'

// -- Private DNS Zones --
module dnsZone1 'modules/dnsZone.bicep' = {
  name: 'zone1'
  params: {
    zoneName: privateStorageBlobDnsZoneName
    tags: tags
  }
}

module dnsZone2 'modules/dnsZone.bicep' = {
  name: 'zone2'
  params: {
    zoneName: privateStorageFileDnsZoneName
    tags: tags
  }
}

output blobZoneName string = privateStorageBlobDnsZoneName
output fileZoneName string = privateStorageFileDnsZoneName
output blobZoneId string = dnsZone1.outputs.zoneId
output fileZoneId string = dnsZone2.outputs.zoneId
