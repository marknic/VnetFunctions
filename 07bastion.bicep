param bastionSubnetId string
param vmSubnetId string
param adminPassword string = 'HeWZ1T4XqVLa#R2*'
param adminUsername string = 'azureuser'

param vmName string = 'jumpserverVm'

module vm 'modules/vm.bicep' = {
  name: vmName
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    vmName: vmName
    subnetId: vmSubnetId
  }
}

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
