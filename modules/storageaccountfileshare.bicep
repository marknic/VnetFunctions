
param storageAccountName string
param fileShareName string

resource functionContentShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${storageAccountName}/default/${fileShareName}'
}
