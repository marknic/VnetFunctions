@description('Name of the storage account to create.')
param storageAccountName string

@description('Region (datacenter) where this resource is to be deployed')
param location string = resourceGroup().location

@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string = 'StorageV2'

@description('Storage Account type')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param storageAccountSku string = 'Standard_ZRS'

@description('list of standard resource tags.')
param tags object = {}

@description('The principal to assign the role to')
param principalId string

param subscriptionId string = subscription().subscriptionId

//
// Variables
//

var roleBlob = resourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
var roleFile = resourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb')

//
// Resources
//

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: kind
  tags: tags
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource roleAssignBlob 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('Storage Blob Data Owner', 'FunctionApp', subscriptionId)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleBlob
  }
  scope: storageAccount
}

resource roleAssignFile 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('Storage File Data SMB Share Contributor', 'FunctionApp', subscriptionId)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleFile
  }
  scope: storageAccount
}

output id string = storageAccount.id
output name string = storageAccount.name
