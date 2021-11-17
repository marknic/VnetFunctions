# Setup - read parameters file for some basic information
$parameterFileIn = 'params.network.json'
$parameterFileOut = 'params.networkout.json'

# Converting the JSON text to an object
$parameters = Get-Content $parameterFileIn | ConvertFrom-Json

$subscriptionId = $parameters.parameters.subscriptionId.value
$location = $parameters.parameters.location.value
$resourceGroupName = $parameters.parameters.resourceGroupName.value

$nsgIdBase = "/subscriptions/$($parameters.parameters.subscriptionId.value)/resourceGroups/$($parameters.parameters.resourceGroupName.value)/providers/Microsoft.Network/networkSecurityGroups"

foreach ($subnet in $parameters.parameters.subnets.value) {
  $nsgId = "$($nsgIdBase)/$($subnet.properties.networkSecurityGroup.id)"
  $subnet.properties.networkSecurityGroup.id = $nsgId
}

$parameters.parameters.PsObject.Members.Remove("subscriptionId")
$parameters.parameters.PsObject.Members.Remove("resourceGroupName")
$parameters.parameters.PsObject.Members.Remove("location")

$parameters | ConvertTo-Json -Depth 8 | Set-Content $parameterFileOut

# Setting the context to the appropriate subscription
az account set --subscription $subscriptionId

# Create the resource group if it doesn't already exist
if ($(az group exists --name $resourceGroupName) -eq $false) {
  az group create -l $location -n $resourceGroupName
}

# Deploy the main.bicep template
$deployResult = $(az deployment group create -g $resourceGroupName --template-file '.\createTestNetwork.bicep' --parameters $parameterFileOut)

if (!$?) {
  Write-Error "Error deploying the main.bicep template.  Exiting"
  Exit
}
