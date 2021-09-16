$resourceGroupName = "Functions-In-A-Vnet-RG"

az deployment group create -g $resourceGroupName --template-file '.\test.bicep'
