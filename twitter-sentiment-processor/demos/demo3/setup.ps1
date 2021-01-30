# This script will run an ARM template deployment to deploy all the
# required resources into Azure. All the keys, tokens and endpoints
# will be automatically retreived and passed to the helm chart used
# in deployment. The only requirement is to populate the mysecrets.yaml
# file in the demochart folder with the twitter tokens, secrets and keys.
# If you already have existing infrastructure do not use this file.
# Simply fill in all the values of the mysecrets.yaml file and call heml
# install passing in that file using the -f flag.
# Requirements:
# Helm 3+
# PowerShell Core 7 (runs on macOS, Linux and Windows)
# Azure CLI (log in, runs on macOS, Linux and Windows)
[CmdletBinding()]
param (
   [Parameter(
      Position = 0,
      HelpMessage = "The name of the resource group to be created. All resources will be place in the resource group and start with name."
   )]
   [string]
   $rgName = "daprtweet",

   [Parameter(
      Position = 1,
      HelpMessage = "The version of the dapr runtime version to deploy."
   )]
   [string]
   $daprVersion = "1.0.0-rc.2"
)

# Deploy the infrastructure
$deployment = $(az deployment sub create --template-file .\main.json --parameters rgName=$rgName --output json) | ConvertFrom-Json

# Get all the outputs
$aksName = $deployment.properties.outputs.aksName.value
$storageAccountKey = $deployment.properties.outputs.storageAccountKey.value
$serviceBusEndpoint = $deployment.properties.outputs.serviceBusEndpoint.value
$storageAccountName = $deployment.properties.outputs.storageAccountName.value
$cognitiveServiceKey = $deployment.properties.outputs.cognitiveServiceKey.value
$cognitiveServiceEndpoint = $deployment.properties.outputs.cognitiveServiceEndpoint.value

Write-Verbose "aksName = $aksName"
Write-Verbose "storageAccountKey = $storageAccountKey"
Write-Verbose "serviceBusEndpoint = $serviceBusEndpoint"
Write-Verbose "storageAccountName = $storageAccountName"
Write-Verbose "cognitiveServiceKey = $cognitiveServiceKey"
Write-Verbose "cognitiveServiceEndpoint = $cognitiveServiceEndpoint"

# Get the credentials to use with dapr init and helm install
az aks get-credentials --resource-group $rgName --name "$aksName"

# Initialize Dapr
dapr init --kubernetes --runtime-version $daprVersion

# Install the demo into the cluster
helm install demo3 .\demochart -f .\demochart\mysecrets.yaml `
   --set serviceBus.connectionString=$serviceBusEndpoint `
   --set cognitiveService.token=$cognitiveServiceKey `
   --set cognitiveService.endpoint=$cognitiveServiceEndpoint `
   --set tableStorage.key=$storageAccountKey `
   --set tableStorage.name=$storageAccountName

# Make sure service is ready
$service = $(k get services viewer --output json) | ConvertFrom-Json

while ($null -eq $service.status.loadBalancer.ingress) {
   Write-Output 'Services not ready retry in 30 seconds.'
   Start-Sleep -Seconds 30
   $service = $(k get services viewer --output json) | ConvertFrom-Json
}

Write-Output "Your app is accesable from http://$($service.status.loadBalancer.ingress[0].ip)"