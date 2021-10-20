
param privateLinkFuncName string
param FunctionPrivateZoneName string


resource functionPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: FunctionPrivateZoneName
}

resource dnsZoneFunc 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: privateLinkFuncName
  parent: functionPrivateZone
  properties: {
    metadata: {
      creator: 'Created via Bicep template'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: privateEndpointZoneSites.outputs.privateEndpointIp
      }
    ]
  }
}

resource dnsZoneScm 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privateLinkFuncName}.scm'
  parent: privateZoneFunction
  properties: {
    metadata: {
      creator: 'Created via Bicep template'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: privateEndpointZoneSites.outputs.privateEndpointIp
      }
    ]
  }
}
