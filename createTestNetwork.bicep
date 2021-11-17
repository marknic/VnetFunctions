@description('Common tags object for all resources')
param resourceTags object

// Standarized naming convention values
@description('Standard naming convention prefix')
@minLength(2)
@maxLength(4)
param prefix string

@description('Standard naming convention suffix/number')
@minLength(2)
@maxLength(6)
param suffix string

@description('Standard naming convention application name/abbreviation')
@minLength(3)
@maxLength(12)
param appName string

@allowed([
  'Dev'
  'Test'
  'Perf'
  'NonProd'
  'Prod'
])
param appEnvironment string
param subnets array
param vnetAddress string = '10.4'
param vnetMask string = '16'

param deployDate object = {
  'DeployDate': utcNow('d')
}

param tags object = union(resourceTags, deployDate)

var dashName = toLower('${appEnvironment}-${prefix}-${appName}-${suffix}')

var vnetName = '${dashName}-vnet'

module nsgs 'modules/networkSecurityGroups.bicep' = {
  name: 'netSecGrps'
}

module parentVnet '01vnet.bicep' = {
  name: 'applictionVnet'
  params: {
    vnetName: vnetName
    tags: tags
    subnets: subnets
    vnetAddress: vnetAddress
    vnetMask: vnetMask
  }
  dependsOn: [
    nsgs
  ]
}

module bastion '02bastion.bicep' = {
  name: 'bastionConnect'
  params: {
    bastionSubnetId: parentVnet.outputs.AzureBastionSubnetId
    vmSubnetId: parentVnet.outputs.VmSubnetId
  }
  dependsOn: [
    parentVnet
  ]
}
