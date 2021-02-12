param agentCount int = 3
param osDiskSizeGB int = 128
param location string = 'eastus2'
param k8sversion string = '1.19.6'
param agentVMSize string = 'Standard_A2_v2'
param servicePrincipalClientId string = 'msi'

var sbApiVersion = '2017-04-01'
var csApiVersion = '2017-04-18'
var stgApiVersion = '2019-06-01'
var defaultSASKeyName = 'RootManageSharedAccessKey'
var sbName = concat('sb', uniqueString(resourceGroup().id))
var csName = concat('cs', uniqueString(resourceGroup().id))
var aksName = concat('aks', uniqueString(resourceGroup().id))
var dnsPrefix = '${aksName}-dns'
var stgName = toLower(concat('stg', uniqueString(resourceGroup().id)))
var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', stgName)
var cognitiveServicesId = resourceId('Microsoft.CognitiveServices/accounts/', csName)
var authRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', sbName, defaultSASKeyName)

resource stg 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: stgName // must be globally unique
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
}

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

resource sb 'Microsoft.ServiceBus/namespaces@2017-04-01' = {
  name: sbName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: aksName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  properties: {
    kubernetesVersion: k8sversion
    enableRBAC: true
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        availabilityZones: [
          '1'
        ]
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'kubenet'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: true
      }
      azurePolicy: {
        enabled: false
      }
    }
    servicePrincipalProfile: {
      clientId: servicePrincipalClientId
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output clusterName string = aksName
output storageAccountName string = stgName
output cognitiveServiceKey string = listkeys(cognitiveServicesId, csApiVersion).key1
output storageAccountKey string = listKeys(storageAccountId, stgApiVersion).keys[0].value
output cognitiveServiceEndpoint string = reference(cognitiveServicesId, csApiVersion).endpoint
output serviceBusEndpoint string = listkeys(authRuleResourceId, sbApiVersion).primaryConnectionString
