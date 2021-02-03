#!/bin/bash

# This script will run an ARM template deployment to deploy all the
# required resources into Azure. All the keys, tokens and endpoints
# will be automatically retreived and set as required environment
# variables.
# Requirements:
# Azure CLI (log in)

# This script is setting environment variables needed by the processor.
# There for you must run this script using the source command.
# source setup.sh
# If you just run the command using ./setup.sh the resources in Azure will be
# created but the environment variables will not be set.

# This function uses grep to get the output value from the deployment when
# passed the name.
# grep (1) get the line with the value
# grep (2) gets the last value with quotes
# grep (3) gets the value no quotes
function getOutput {
   echo $(echo $deployment | grep -oE "$1[^}]+" | grep -oE '"[^"]+" ' | grep -oE '[^" ]+')
}

# The name of the resource group to be created. All resources will be place in
# the resource group and start with name.
rgName=$1
rgName=${rgName:-twitterDemo2}

# The version of the dapr runtime version to deploy.
daprVersion=$2
daprVersion=${daprVersion:-1.0.0-rc.3}

# The location to store the meta data for the deployment.
location=$3
location=${location:-eastus}

# Deploy the infrastructure
deployment=$(az deployment sub create --location $location --template-file ./main.json --parameters rgName=$rgName --output json)

# Get all the outputs
cognitiveServiceKey=$(getOutput 'cognitiveServiceKey')
cognitiveServiceEndpoint=$(getOutput 'cognitiveServiceEndpoint')

export CS_TOKEN=$cognitiveServiceKey
export CS_ENDPOINT=$cognitiveServiceEndpoint

echo "You can now run the processor from this terminal."
