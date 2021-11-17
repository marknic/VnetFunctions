param privateSiteName string
param privateStorageName string

param privateZoneNameSites string
param privateZoneNameBlob string
param privateZoneNameFile string

param ipAddressSites string
param ipAddressBlob string
param ipAddressFile string

//
// Resources
//

resource dnsZoneSites 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateZoneNameSites
}

resource dnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateZoneNameBlob
}

resource dnsZoneFile 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateZoneNameFile
}

resource privateDnsZoneSetting 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: privateSiteName
  parent: dnsZoneSites
  properties: {
    metadata: {
      creator: 'Created via Bicep template'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: ipAddressSites
      }
    ]
  }
}

resource privateDnsZoneSettingScm 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privateSiteName}.scm'
  parent: dnsZoneSites
  properties: {
    metadata: {
      creator: 'Created via Bicep template'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: ipAddressSites
      }
    ]
  }
}

resource privateDnsZoneSettingBlob 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: privateStorageName
  parent: dnsZoneBlob
  properties: {
    metadata: {
      creator: 'Created via Bicep template'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: ipAddressBlob
      }
    ]
  }
}

resource privateDnsZoneSettingFile 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: privateStorageName
  parent: dnsZoneFile
  properties: {
    metadata: {
      creator: 'Created via Bicep template'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: ipAddressFile
      }
    ]
  }
}
