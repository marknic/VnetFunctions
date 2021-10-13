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

if (!$?) {
  Write-Error "Error deploying the main.bicep template.  Exiting"
  Exit
}

# Convert the output data into a PS object
$outputData = $deployResult | ConvertFrom-Json

# Get the values from the output object
$fileShareName = $outputData.properties.outputs.fileShareName.value
$sourceStorageAccountName = $outputData.properties.outputs.backingStoreTmpAccountName.value
$destinationStorageAccountName = $outputData.properties.outputs.backingStoreAccountName.value
$functionAppName = $outputData.properties.outputs.functionAppName.value


# Make sure the site is initialized and running
$responseBody = $(Invoke-RestMethod -Method Get -Uri "http://$($functionAppName).azurewebsites.net")


# FUNCTIONS FUNCTIONS FUNCTIONS FUNCTIONS FUNCTIONS FUNCTIONS
# FUNCTIONS FUNCTIONS FUNCTIONS FUNCTIONS FUNCTIONS FUNCTIONS

# Get the access key from a storage account
function Get-StorageKey {
  param (
    [string]$subscription,
    [string]$resourceGroup,
    [string]$storageAccountName
  )

  # Set for retry
  for($i=0; $i -lt 3; $i++) {

    $keys = $(az storage account keys list --account-name $storageAccountName --resource-group $resourceGroup --subscription $subscription)

    if ($keys) {
      return ($keys | ConvertFrom-Json)[0].value
    }
  }

  return $null
}


function Set-NetworkRule {
  param (
    [string]$resourceGroup,
    [string]$storageAccountName,
    [string]$publicIpAddress
  )

  az storage account network-rule add -g $resourceGroup --account-name $storageAccountName --ip-address $publicIpAddress
}

function Get-ClientIp {

  $maxRetries = 3
  $publicIpAddress = $null

  # Set to retry if there is a network failure
  for ($i = 0; $i -lt $maxRetries; i++) {
    # Call an outside service to get our public IP address
    $myIpBody = $(Invoke-RestMethod -Method Get -Uri "http://checkip.dyndns.org")

    # do a regex match to hopefully identify the IP address in the response
    $mtch = $($myIpBody.html.body -match '(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}')

    # was there a match
    if ($mtch -eq $true) {
      # if so, create a network rule in the storage account
      $publicIpAddress = $Matches.0
      break
    }

    if ($i -eq ($maxRetries - 1)) {
      Write-Host 'Failed to get the client IP address'
    }
  }

  return $publicIpAddress
}


function Build-FolderStructure {
  param (
    [string]$folderName,
    [string]$sourceKey,
    [string]$sourceStorageAccountName,
    [string]$destinationKey,
    [string]$destinationStorageAccountName,
    [string]$fileShareName
  )

  if ($FolderName) {
    $list = $(az storage directory list --account-key $sourceKey --account-name $sourceStorageAccountName --share-name $fileShareName --name $folderName | ConvertFrom-Json)
  }
  else {
    $list = $(az storage directory list --account-key $destinationKey --account-name $destinationStorageAccountName --share-name $fileShareName | ConvertFrom-Json)
  }

  if ($list) {
    foreach ($dir in $list) {

      if ($FolderName) {
        $searchFolder = $folderName + "/" + $dir.name
      }
      else {
        $searchFolder = $dir.name
      }

      $exists = $(az storage directory exists `
          --account-key $destinationKey `
          --account-name $destinationStorageAccountName `
          --share-name $fileShareName `
          --name $searchFolder )

      if ($($exists | ConvertFrom-Json).exists -eq $False) {

        Write-Host 'Creating folder: ' + $searchFolder

        az storage directory create  `
          --account-key $destinationKey `
          --account-name $destinationStorageAccountName `
          --share-name $fileShareName `
          --name $searchFolder
      }

      Write-Host $searchFolder

      Build-FolderStructure `
        -folderName $searchFolder `
        -sourceKey $sourceKey `
        -sourceStorageAccountName $sourceStorageAccountName `
        -destinationKey $destinationKey `
        -destinationStorageAccountName $destinationStorageAccountName `
        -fileShareName $FileShareName
    }
  }
}

function ConvertTo-Bicep-Parameter {
  param (
    [PSObject] $jsonData
  )

  $jsonSettings = $jsonData | ConvertTo-Json

  $jsonSettings=$jsonSettings.Replace("`n", "")
  $jsonSettings=$jsonSettings.Replace("`r", "")
  $jsonSettings=$jsonSettings.Replace(" ", "")
  $jsonSettings=$jsonSettings.Replace("`"", "`"`"`"")

  return $jsonSettings
}

#$clientIp = Get-ClientIp

# set these network rules to allow the script to copy files between the two storage accounts.
# Set-NetworkRule -subscription $subscriptionId -resourceGroup $resourceGroupName -storageAccountName $sourceStorageAccountName -publicIpAddress $clientIp
# Set-NetworkRule -subscription $subscriptionId -resourceGroup $resourceGroupName -storageAccountName $destinationStorageAccountName -publicIpAddress $clientIp

#Start-Sleep 5

$sourceKey = Get-StorageKey -subscription $subscriptionId -resourceGroup $resourceGroupName -storageAccountName $sourceStorageAccountName
$destinationKey = Get-StorageKey -subscription $subscriptionId -resourceGroup $resourceGroupName -storageAccountName $destinationStorageAccountName
$destinationConnString = "DefaultEndpointsProtocol=https;AccountName=$($destinationStorageAccountName);AccountKey=$($destinationKey);EndpointSuffix=core.windows.net"

# Copy all of the files and as much of the folder structure as we can
az storage file copy start-batch `
  --source-account-key $sourceKey `
  --source-account-name $sourceStorageAccountName `
  --source-share $fileShareName `
  --connection-string $destinationConnString `
  --destination-share $fileShareName


# Follow-up with adding all of the empty folders that don't get created in the copy process
# Build-FolderStructure -sourceKey $sourceKey `
#   -sourceStorageAccountName $sourceStorageAccountName `
#   -destinationKey $destinationKey `
#   -destinationStorageAccountName $destinationStorageAccountName `
#   -FileShareName $fileShareName


$containers = $(az storage container list --account-key $sourceKey --account-name $sourceStorageAccountName --auth-mode key) | ConvertFrom-Json

# Copy all of the files that exist in blob storage over to the destination storage account
foreach ($container in $containers) {

  az storage container create --account-key $destinationKey --account-name $destinationStorageAccountName --name $container.name

  az storage blob copy start-batch `
  --auth-mode key `
  --source-account-key $sourceKey --source-account-name $sourceStorageAccountName `
  --source-container $container.name `
  --account-key $destinationKey --account-name $destinationStorageAccountName `
  --destination-container $container.name
}


$appSettingsObject = $(az functionapp config appsettings list --name $functionAppName -g $resourceGroupName | ConvertFrom-Json)

if (!$?) {
  Write-Error "Error deploying the main.bicep template - Getting the current App Settings from the Function App.  Exiting"
  Exit
}

$settingsObject = New-Object PSObject

foreach($setting in $appSettingsObject) {
  if ($setting.name -eq "AzureWebJobsStorage" -or $setting.name -eq "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING") {
    $setting.value = $destinationConnString
  }
  Add-Member -InputObject $settingsObject -MemberType NoteProperty -Name $setting.name -Value $setting.value
}

Add-Member -InputObject $settingsObject -MemberType NoteProperty -Name "WEBSITE_VNET_ROUTE_ALL" -Value "1"
Add-Member -InputObject $settingsObject -MemberType NoteProperty -Name "WEBSITE_CONTENTOVERVNET" -Value "1"
Add-Member -InputObject $settingsObject -MemberType NoteProperty -Name "WEBSITE_DNS_SERVER" -Value "168.63.129.16"

$jsonSettings = ConvertTo-Bicep-Parameter -jsonData $settingsObject

az deployment group create -g $resourceGroupName --template-file '.\06updateAppSettings.bicep' --parameters functionAppName=$functionAppName settings=$jsonSettings

if (!$?) {
  Write-Error "Error deploying the main.bicep template - Updating the App Settings (06updateAppSettings.bicep).  Exiting"
  Exit
}

