
param prefix string = 'mn'

param suffix string = '01'

param appName string = 'mnfuncapp'

param appEnvironment string = 'dev'

var nodashName = toLower('${appEnvironment}${prefix}${appName}${suffix}')

var storageAccountName = '${nodashName}sa'

var vnetName = 'vnet-marknic10dot4'

var tags = {
    'DeptName': 'Innovation'
    'LOB': 'Innovation'
    'EntType': 'dev'
    'DeployDate': '01/01/1970'
    'Deployer': 'Mark Nichols'
    'Sensitivity': 'NonSensitive'
    'SenType': 'Not Applicable'
    'SubDivision': 'Innovation'
    'Department': 'Innovation'
    'CostCenter': 'IT Innovation 1234'
    'CostCode': '1234567890'
}


param privateZone01Blob string = 'blobPrivateDnsZoneGroup'
param privateZone01File string = 'filePrivateDnsZoneGroup'


module dnsZoneGroup1 '05privateEndpointZoneGroups.bicep' = {
  name: 'zoneGroups'
  params: {
    blobZoneId: privateZone01Blob
    fileZoneId: privateZone01File
    storageAccountName: storageAccountName
  }
}


module privateEndpoint1 '04privateEndpoints.bicep' = {
    name: 'endpoints'
    params: {
      tags: tags
      storageAccountId: storage01.id
      storageAccountName: storageAccountName
      subnetName: 'sn-pep-2-0-24'
      vnetName: vnetName
    }
  }


  resource storage01 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
     name: storageAccountName
  }

