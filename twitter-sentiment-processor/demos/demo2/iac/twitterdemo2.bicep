param location string = 'eastus2'

var csApiVersion = '2017-04-18'
var csName = concat('cs', uniqueString(resourceGroup().id))
var cognitiveServicesId = resourceId('Microsoft.CognitiveServices/accounts/', csName)

resource cs 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: csName
  kind: 'CognitiveServices'
  location: location
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: csName
  }
}

output cognitiveServiceKey string = listkeys(cognitiveServicesId, csApiVersion).key1
output cognitiveServiceEndpoint string = reference(cognitiveServicesId, csApiVersion).endpoint
