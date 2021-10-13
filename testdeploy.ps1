$resourceGroupName = "Functions-In-A-Vnet-RG"

$result = $(az deployment group create -g $resourceGroupName --template-file '.\modules\storageaccount_test.bicep')

