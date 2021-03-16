# This script will run an ARM template deployment to deploy all the
# required resources into Azure. All the keys, tokens and endpoints
# will be automatically retreived and set as required environment
# variables.
# Requirements:
# PowerShell Core 7 (runs on macOS, Linux and Windows)
# Azure CLI (log in, runs on macOS, Linux and Windows)
[CmdletBinding()]
param (
   [Parameter(
      Position = 0,
      HelpMessage = "The name of the resource group to be created. All resources will be place in the resource group and start with this name."
   )]
   [string]
   $rgName = "twitterDemo",

   [Parameter(
      Position = 1,
      HelpMessage = "The location to store the meta data for the deployment."
   )]
   [string]
   $location = "eastus"
)

# Deploy the infrastructure
$deployment = $(az deployment sub create --name $rgName `
   --location $location `
   --template-file ./iac/main.json `
   --parameters rgName=$rgName `
   --parameters location=$location `
   --output json) | ConvertFrom-Json

# Get all the outputs
$cognitiveServiceKey = $deployment.properties.outputs.cognitiveServiceKey.value
$cognitiveServiceEndpoint = $deployment.properties.outputs.cognitiveServiceEndpoint.value

Write-Verbose "cognitiveServiceKey = $cognitiveServiceKey"
Write-Verbose "cognitiveServiceEndpoint = $cognitiveServiceEndpoint"

$env:CS_TOKEN=$cognitiveServiceKey
$env:CS_ENDPOINT=$cognitiveServiceEndpoint

Write-Output "You can now run the processor from this terminal.`n"