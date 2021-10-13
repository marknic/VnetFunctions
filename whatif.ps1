
$resourceGroupName = "Functions-In-A-Vnet-RG"
$location = "eastus"

if ($(az group exists --name $resourceGroupName) -eq $false) {
    az group create -l $location -n $resourceGroupName
}

$output = $(az deployment group what-if --mode Incremental --no-pretty-print --resource-group $resourceGroupName --template-file '.\main.bicep' --parameters params.functionapp.json)

$output
