targetScope = 'subscription'

param rgName string = 'twitterdemo3'
param location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgName
  location: location
}

module twitterDemo './twitterdemo3.bicep' = {
  name: 'twitterdemo3'
  scope: resourceGroup(rg.name)
}

output aksName string = twitterDemo.outputs.clusterName
output storageAccountKey string = twitterDemo.outputs.storageAccountKey
output storageAccountName string = twitterDemo.outputs.storageAccountName
output serviceBusEndpoint string = twitterDemo.outputs.serviceBusEndpoint
output cognitiveServiceKey string = twitterDemo.outputs.cognitiveServiceKey
output cognitiveServiceEndpoint string = twitterDemo.outputs.cognitiveServiceEndpoint