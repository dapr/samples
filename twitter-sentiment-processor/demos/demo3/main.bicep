targetScope = 'subscription'

param rgName string = 'daprIac'
param location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgName
  location: location
}

module twitterDemo './twitterdemo.bicep' = {
  name: 'twitterDemo'
  scope: resourceGroup(rg.name)
  params:{
    baseName: rgName
  }
}

output aksName string = twitterDemo.outputs.clusterName
output storageAccountKey string = twitterDemo.outputs.storageAccountKey
output storageAccountName string = twitterDemo.outputs.storageAccountName
output serviceBusEndpoint string = twitterDemo.outputs.serviceBusEndpoint
output cognitiveServiceKey string = twitterDemo.outputs.cognitiveServiceKey
output cognitiveServiceEndpoint string = twitterDemo.outputs.cognitiveServiceEndpoint