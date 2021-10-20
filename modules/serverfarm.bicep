param appServicePlanName string

@description('Region (datacenter) where this resource is to be deployed')
param location string
param tags object

@description('The name/size of the compute to use for the Functions using this App Service Plan.')
@allowed([
  'EP1'
  'EP2'
  'EP3'
])
param skuSizeName string

@description('The number of instances this plan can scale to under load.')
param maximumElasticWorkerCount int = 20

param perSiteScaling bool = false

@description('The number of instances allocated to your plan. It is the count of the always ready instances in this plan.')
param capacity int = 1

@description('Value should be true if the OS is Linux.')
param isLinux bool

resource appPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  kind: 'elastic'
  location: location
  tags: tags
  properties: {
    workerTierName: 'string'
    hostingEnvironmentProfile: {
      id: 'string'
    }
    perSiteScaling: perSiteScaling
    maximumElasticWorkerCount: maximumElasticWorkerCount
    reserved: isLinux
  }
  sku: {
    name: skuSizeName
    tier: 'ElasticPremium'
    size: skuSizeName
    family: 'EP'
    capacity: capacity
  }
}
