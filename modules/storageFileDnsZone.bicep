param zoneName string

// -- Private DNS Zones --
resource storageFileDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
}

output zoneId string = storageFileDnsZone.id
