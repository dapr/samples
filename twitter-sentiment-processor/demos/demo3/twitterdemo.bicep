param baseName string
param agentCount int = 3
param osDiskSizeGB int = 128
param location string = 'eastus2'
param agentVMSize string = 'Standard_A2_v2'
param servicePrincipalClientId string = 'msi'

var sbName = '${baseName}sb'
var csName = '${baseName}cs'
var stgName = '${baseName}stg'
var aksName = '${baseName}aks'
var dnsPrefix = '${aksName}-dns'
var sbApiVersion = '2017-04-01'
var csApiVersion = '2017-04-18'
var stgApiVersion = '2019-06-01'
var defaultSASKeyName = 'RootManageSharedAccessKey'
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

resource topic 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  name: '${sb.name}/tweets'
  properties: {
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enableBatchedOperations: false
    supportOrdering: false
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource sub 'Microsoft.ServiceBus/namespaces/topics/Subscriptions@2017-04-01' = {
  name: '${topic.name}/processed'
  properties: {
    lockDuration: 'PT1M'
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    maxDeliveryCount: 1
    enableBatchedOperations: false
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: aksName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  properties: {
    kubernetesVersion: '1.19.3'
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