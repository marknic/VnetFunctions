param bastionSubnetId string
param vmSubnetId string

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'bastionPublicIP'
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
     name: 'Standard'
  }
}

resource bastionRes 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: 'accessBastion'
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastionPublicIp'
        properties: {
          publicIPAddress: {
            id: publicIPAddress.id
          }
          subnet: {
            id: bastionSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddress
  ]
}

module jumpbox 'modules/linuxJumpServerVm.bicep' = {
  name: 'linuxJumpbox'
  params: {
    authenticationType: 'password'
    adminPasswordOrKey: 'vyT7D8jG02P$tys%'
    subnetId: vmSubnetId
  }
}
