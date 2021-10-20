#az login

# Setup - read parameters file for some basic information
$parameterFile = 'params.functionapp.json'

# Converting the JSON text to an object
$parameters = Get-Content $parameterFile | ConvertFrom-Json

$subscriptionId = $parameters.parameters.subscriptionId.value
$location = $parameters.parameters.location.value
$resourceGroupName = $parameters.parameters.resourceGroupName.value

# Setting the context to the appropriate subscription
az account set --subscription $subscriptionId

# Create the resource group if it doesn't already exist
if ($(az group exists --name $resourceGroupName) -eq $false) {
  az group create -l $location -n $resourceGroupName
}

# Deploy the main.bicep template
$deployResult = $(az deployment group create -g $resourceGroupName --template-file '.\main.bicep' --parameters params.functionapp.json)

$deployResult