@description('Name of the private zone to be created.')
param zoneName string

@description('list of standard resource tags.')
param tags object = {}

//
// Resources
//

// -- Private DNS Zones --
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
  tags: tags
}

output zoneId string = dnsZone.id
