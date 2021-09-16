param zoneName string
param tags object

// -- Private DNS Zones --
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
  tags: tags
}

output zoneId string = dnsZone.id
