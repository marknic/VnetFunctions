param vnetName string
param tags object

param addressPrefix string = '10.0.0.0/16'

param subnets array

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

output GeneralUseSubnet object = vnet.properties.subnets[0]
output VmSubnet object = vnet.properties.subnets[1]
output PrivateEndpointSubnet object = vnet.properties.subnets[2]
output FunctionSubnet object = vnet.properties.subnets[3]
output AzureBastionSubnet object = vnet.properties.subnets[4]

