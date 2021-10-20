param vnetAddress string = '10.0'
param vnetMask string = '16'
param vnetAddressPrefix string = '${vnetAddress}.0.0/${vnetMask}'
param vnetName string
param tags object
param subnets array

module vnet 'modules/vnet.bicep' = {
  name: 'basevnet'
  params: {
    vnetName: vnetName
    addressPrefix: vnetAddressPrefix
    tags: tags
    subnets: subnets
  }
}

output vnetId string = vnet.outputs.vnetId

output GeneralUseSubnetId string = vnet.outputs.GeneralUseSubnet.Id
output VmSubnetId string = vnet.outputs.VmSubnet.Id
output PrivateEndpointSubnetId string = vnet.outputs.PrivateEndpointSubnet.Id
output FunctionSubnetId string = vnet.outputs.FunctionSubnet.Id
output AzureBastionSubnetId string = vnet.outputs.AzureBastionSubnet.Id
