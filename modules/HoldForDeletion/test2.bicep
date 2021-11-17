

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' existing = {
  name: 'mnfunctionwindows-asp'
}

resource azureFunction 'Microsoft.Web/sites@2020-12-01' existing = {
  name: 'mnwindowsfunc'

}

// az deployment group create -g function-test-rg --template-file '.\test2.bicep'
output fprops object = azureFunction.properties
output pprops object = appServicePlan.properties

