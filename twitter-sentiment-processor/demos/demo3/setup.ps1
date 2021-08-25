# This script will run an ARM template deployment to deploy all the
# required resources into Azure. All the keys, tokens and endpoints
# will be automatically retreived and passed to the helm chart used
# in deployment. The only requirement is to populate the mysecrets.yaml
# file in the demochart folder with the twitter tokens, secrets and keys.
# If you already have existing infrastructure do not use this file.
# Simply fill in all the values of the mysecrets.yaml file and call helm
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
   $rgName = "twitterDemo",

   [Parameter(
      Position = 1,
      HelpMessage = "The location to store the meta data for the deployment."
   )]
   [string]
   $location = "eastus",

   [Parameter(
      Position = 2,
      HelpMessage = "The version of the dapr runtime version to deploy."
   )]
   [string]
   $daprVersion = "1.3.0",

   [Parameter(
      Position = 3,
      HelpMessage = "The version of k8s control plane."
   )]
   [string]
   $k8sVersion
)

if (-not $PsBoundParameters.ContainsKey('k8sVersion')) {
   $k8sVersion = $((az aks get-versions --location $location -o json | convertfrom-json).orchestrators.orchestratorVersion | sort-object -Descending | select-object -First 1)
}

function Get-IP {
   [CmdletBinding()]
   param (
      [string]
      $serviceName
   )
   # Make sure service is ready
   kubectl get services $serviceName --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

# Deploy the infrastructure
az deployment sub create --name $rgName `
   --location $location `
   --template-file ./iac/main.json `
   --parameters location=$location `
   --parameters rgName=$rgName `
   --parameters k8sversion=$k8sVersion `
   --output none

$deployment = az deployment sub show --name $rgName --output json | ConvertFrom-Json

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

# Confirm Dapr is running. If you run helm install to soon the Dapr side car
# will not be injected.
$status = dapr status --kubernetes

# Once all the services are running they will all report True instead of False.
# Keep checking the status until you don't find False
$x = 0
while ($($status | Select-String 'dapr-system  False').Matches.Length -ne 0) {
   $x++
   Write-Progress -Activity "Dapr starting. Please wait... " -PercentComplete $x
   Start-Sleep -Seconds 1
   $status = dapr status --kubernetes
}
Write-Output "Dapr ready!"

# Copy the twitter component file from the demos/components folder to the
# templates folder. Copy this file removes the need for the user to set
# those values second time.
Copy-Item -Path ../components/twitter.yaml -Destination ./demochart/templates/ -Force

# Install the demo into the cluster
helm upgrade --install demo3 ./demochart `
   --set serviceBus.connectionString=$serviceBusEndpoint `
   --set cognitiveService.token=$cognitiveServiceKey `
   --set cognitiveService.endpoint=$cognitiveServiceEndpoint `
   --set tableStorage.key=$storageAccountKey `
   --set tableStorage.name=$storageAccountName `
   --set usingPowerShell=True

# Make sure services are ready
$x = 0
do {
   $x++
   Write-Progress -Activity "Getting IP addresses. Please wait..." -PercentComplete $x
   Start-Sleep -Seconds 1
   $viewerIp = Get-IP -serviceName viewer
   $zipkinIp = Get-IP -serviceName publiczipkin
} until ($viewerIp -and $zipkinIp)

Write-Output "`nYour app is accessible from http://$viewerIp"
Write-Output "Zipkin is accessible from http://$zipkinIp`n"
