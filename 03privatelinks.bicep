param tags object
param virtualNetworkId string
param storageAccountName string
param zoneNameBlob string
param zoneNameFile string

var linkNameBlob = '${storageAccountName}-blob-link'
var linkNameFile = '${storageAccountName}-file-link'

module zonelink1 'modules/dnsZoneLink.bicep' = {
  name: 'zonelinkblob'
  params: {
    tags: tags
    virtualNetworkId: virtualNetworkId
    linkName: linkNameBlob
    zoneName: zoneNameBlob
  }
}

module zonelink2 'modules/dnsZoneLink.bicep' = {
  name: 'zonelinkfile'
  params: {
    tags: tags
    virtualNetworkId: virtualNetworkId
    linkName: linkNameFile
    zoneName: zoneNameFile
  }
}

output blobLinkName string = linkNameBlob
output fileLinkName string = linkNameFile
