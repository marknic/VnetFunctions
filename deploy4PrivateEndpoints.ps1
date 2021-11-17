

az deployment group create -g $resourceGroupName --template-file './addPrivateEndpoints.bicep'



Write-Host "Retrieving App Settings"  -ForegroundColor green
$appSettingsObject = $(az functionapp config appsettings list --name $functionAppName -g $resourceGroupName | ConvertFrom-Json)

if (!$?) {
  Write-Error "Error deploying the main.bicep template - Getting the current App Settings from the Function App.  Exiting"
  Exit
}

$settingsObject = New-Object PSObject

Write-Host "Stepping through App Settings building settingsObject"  -ForegroundColor green

foreach ($setting in $appSettingsObject) {
  Add-Member -InputObject $settingsObject -MemberType NoteProperty -Name $setting.name -Value $setting.value
}

Add-Member -InputObject $settingsObject -MemberType NoteProperty -Name "WEBSITE_VNET_ROUTE_ALL" -Value "1"
Add-Member -InputObject $settingsObject -MemberType NoteProperty -Name "WEBSITE_CONTENTOVERVNET" -Value "1"
Add-Member -InputObject $settingsObject -MemberType NoteProperty -Name "WEBSITE_DNS_SERVER" -Value "168.63.129.16"

$jsonSettings = ConvertTo-Bicep-Parameter -jsonData $settingsObject

Write-Host "Deploying 06updateAppSettings.bicep"  -ForegroundColor green

az deployment group create -g $resourceGroupName --template-file '.\06updateAppSettings.bicep' --parameters functionAppName=$functionAppName settings=$jsonSettings

if (!$?) {
  Write-Error "Error deploying a bicep template - Updating the App Settings (06updateAppSettings.bicep).  Exiting"
  Exit
}






