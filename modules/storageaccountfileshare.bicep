
@description('Name of the storage account where the file share is to be created.')
param storageAccountName string

@description('Name of the file share to create.')
param fileShareName string

resource functionContentShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${storageAccountName}/default/${fileShareName}'
}
