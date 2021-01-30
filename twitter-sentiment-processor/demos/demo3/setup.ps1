# Requirements
# Helm 3+
# Azure CLI
[CmdletBinding()]
param (
   [Parameter()]
   [string]
   $rgName = "daprtweet",

   [Parameter()]
   [string]
   $daprVersion = "1.0.0-rc.2"
)

# Deploy the infrastructure
$deployment = $(az deployment sub create --template-file .\main.json --parameters rgName=$rgName --output json) | ConvertFrom-Json

# Get all the outputs
$aksName = $deployment.properties.outputs.aksName.value
$aksFQDN = $deployment.properties.outputs.aksFQDN.value
$storageAccountKey = $deployment.properties.outputs.storageAccountKey.value
$serviceBusEndpoint = $deployment.properties.outputs.serviceBusEndpoint.value
$storageAccountName = $deployment.properties.outputs.storageAccountName.value
$cognitiveServiceKey = $deployment.properties.outputs.cognitiveServiceKey.value
$cognitiveServiceEndpoint = $deployment.properties.outputs.cognitiveServiceEndpoint.value

Write-Verbose "aksName = $aksName"
Write-Verbose "aksFQDN = $aksFQDN"
Write-Verbose "storageAccountKey = $storageAccountKey"
Write-Verbose "serviceBusEndpoint = $serviceBusEndpoint"
Write-Verbose "storageAccountName = $storageAccountName"
Write-Verbose "cognitiveServiceKey = $cognitiveServiceKey"
Write-Verbose "cognitiveServiceEndpoint = $cognitiveServiceEndpoint"

# Get the credentials to use with dapr init and helm install
az aks get-credentials --resource-group $rgName --name "$aksName"

# Initialize Dapr
dapr init --kubernetes

helm install demo3 .\demochart -f .\demochart\mysecrets.yaml `
   --set serviceBus.connectionString=$serviceBusEndpoint `
   --set cognitiveService.token=$cognitiveServiceKey `
   --set cognitiveService.endpoint=$cognitiveServiceEndpoint `
   --set tableStorage.key=$storageAccountKey `
   --set tableStorage.name=$storageAccountName

Write-Output "Your app is accesable from https://$aksFQDN"