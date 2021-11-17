@description('Name of the Application Insights resource to be created.')
param applicationInsightsName string

@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@description('list of standard resource tags')
param tags object = {}

//
// Resources
//

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
