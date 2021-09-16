param vnetName string
param tags object

param addressPrefix string = '10.0.0.0/16'

param subnets array = [
  {
    name: 'subnet001'
    properties: {
      addressPrefix: '10.4.0.0/24'
    }
  }
  {
    name: 'subnet002'
    properties: {
      addressPrefix: '10.0.1.0/24'
    }
  }
]


resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: subnets
  }
}

output vnetId string = vnet.id
