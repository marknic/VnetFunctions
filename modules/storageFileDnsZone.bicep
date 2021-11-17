@description('Name of the private DNS zone to be created.')
param zoneName string

@description('list of standard resource tags.')
param tags object = {}

// -- Private DNS Zones --
resource storageFileDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  tags: tags
  location: 'global'
}

output zoneId string = storageFileDnsZone.id
