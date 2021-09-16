param vnetAddress string = '10.0'
param vnetMask string = '16'
param vnetAddressPrefix string = '${vnetAddress}.0.0/${vnetMask}'
param vnetName string
param tags object
param subnets array

module vnetcreate 'modules/vnet.bicep' = {
  name: 'basevnet'
  params: {
    vnetName: vnetName
    addressPrefix: vnetAddressPrefix
    tags: tags
    subnets: subnets
  }
}

output vnetId string = vnetcreate.outputs.vnetId
