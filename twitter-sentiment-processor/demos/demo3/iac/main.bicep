targetScope = 'subscription'

param location string = 'eastus'
param k8sversion string = '1.19.6'
param rgName string = 'twitterdemo'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgName
  location: location
}

module twitterDemo './twitterDemo3.bicep' = {
  name: 'twitterdemo3'
  scope: resourceGroup(rg.name)
  params: {
     location: location
     k8sversion: k8sversion
  }
}

output aksName string = twitterDemo.outputs.clusterName
output storageAccountKey string = twitterDemo.outputs.storageAccountKey
output storageAccountName string = twitterDemo.outputs.storageAccountName
output serviceBusEndpoint string = twitterDemo.outputs.serviceBusEndpoint
output cognitiveServiceKey string = twitterDemo.outputs.cognitiveServiceKey
output cognitiveServiceEndpoint string = twitterDemo.outputs.cognitiveServiceEndpoint