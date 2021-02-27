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

function getOutput {
   echo $(az deployment sub show --name $rgName --query "properties.outputs.$1.value" --output tsv)
}

# The name of the resource group to be created. All resources will be place in
# the resource group and start with name.
rgName=$1
rgName=${rgName:-twitterDemo}

# The location to store the meta data for the deployment.
location=$2
location=${location:-eastus}

# Deploy the infrastructure
az deployment sub create --name $rgName --location $location --template-file ./iac/main.json --parameters rgName=$rgName --output none

# Get all the outputs
cognitiveServiceKey=$(getOutput 'cognitiveServiceKey')
cognitiveServiceEndpoint=$(getOutput 'cognitiveServiceEndpoint')

export CS_TOKEN=$cognitiveServiceKey
export CS_ENDPOINT=$cognitiveServiceEndpoint

printf "You can now run the processor from this terminal.\n"
