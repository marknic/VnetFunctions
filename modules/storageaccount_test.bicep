param subscriptionId string = 'e752c181-7a2c-4de5-b16b-b3288ed54e42'
param storageAccountName string = 'devmnprivatefunc01sa'

@description('The principal to assign the role to')
param principalId string = '090f1a48-27c2-4a23-a49f-c6cc124027f4'

var roleBlob = resourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
var roleFile = resourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb')

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource roleAssignBlob 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name:  guid('Storage Blob Data Owner', 'FunctionApp' , subscriptionId)
  properties: {
    principalId: principalId
    principalType:  'ServicePrincipal'
    roleDefinitionId: roleBlob
  }
  scope: storageAccount
}

resource roleAssignFile 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('Storage File Data SMB Share Contributor', 'FunctionApp' , subscriptionId)
  properties: {
    principalId: principalId
    principalType:  'ServicePrincipal'
    roleDefinitionId: roleFile
  }
  scope: storageAccount
}

output id string = storageAccount.id
output name string = storageAccount.name
