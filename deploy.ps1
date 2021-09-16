#az login

$resourceGroupName = "Functions-In-A-Vnet-RG"
$location = "eastus"

if ($(az group exists --name $resourceGroupName) -eq $false) {
    az group create -l $location -n $resourceGroupName
}

az deployment group create -g $resourceGroupName --template-file '.\main.bicep' --parameters params.functionapp.json
