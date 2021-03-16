targetScope = 'subscription'

param location string = 'eastus'
param rgName string = 'twitterDemo'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgName
  location: location
}

module twitterDemo './twitterDemo2.bicep' = {
  name: 'twitterDemo2'
  scope: resourceGroup(rg.name)
  params: {
    location: location
 }
}

output cognitiveServiceKey string = twitterDemo.outputs.cognitiveServiceKey
output cognitiveServiceEndpoint string = twitterDemo.outputs.cognitiveServiceEndpoint