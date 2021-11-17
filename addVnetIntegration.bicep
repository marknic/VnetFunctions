@description('Name of the function to be added to the VNET (just the unique name, without the domain.)')
param functionName string = 'devmnprivatefunc01fa'

@description('The full resource ID for the target subnet where the function will be added.')
param subnetId string = '/subscriptions/e752c181-7a2c-4de5-b16b-b3288ed54e42/resourceGroups/Functions-In-A-Vnet-RG/providers/Microsoft.Network/virtualNetworks/dev-mn-privatefunc-01-vnet/subnets/sn-func-3-0-27-d'

resource parentFunction 'Microsoft.Web/sites@2021-02-01' existing = {
  name: functionName
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  parent: parentFunction
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetId
    swiftSupported: true
  }
}
