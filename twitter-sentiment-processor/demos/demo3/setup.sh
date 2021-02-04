#!/bin/bash

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
# Azure CLI (log in)

function getOutput {
   echo $(az deployment sub show --name $rgName --query "properties.outputs.$1.value" --output tsv)
}

# The name of the resource group to be created. All resources will be place in
# the resource group and start with name.
rgName=$1
rgName=${rgName:-twitterDemo3}

# The version of the dapr runtime version to deploy.
daprVersion=$2
daprVersion=${daprVersion:-1.0.0-rc.3}

# The location to store the meta data for the deployment.
location=$3
location=${location:-eastus}

# # Deploy the infrastructure
az deployment sub create --name $rgName --location $location --template-file ./iac/main.json --parameters rgName=$rgName --output none

# Get all the outputs
aksName=$(getOutput 'aksName')
storageAccountKey=$(getOutput 'storageAccountKey')
serviceBusEndpoint=$(getOutput 'serviceBusEndpoint')
storageAccountName=$(getOutput 'storageAccountName')
cognitiveServiceKey=$(getOutput 'cognitiveServiceKey')
cognitiveServiceEndpoint=$(getOutput 'cognitiveServiceEndpoint')

# Get the credentials to use with dapr init and helm install
az aks get-credentials --resource-group $rgName --name "$aksName"

# Initialize Dapr
dapr init --kubernetes --runtime-version $daprVersion

# Confirm Dapr is running. If you run helm install to soon the Dapr side car
# will not be injected.
status=$(dapr status --kubernetes)

# Once all the services are running they will all report True instead of False.
# Keep checking the status until you don't find False
attempts=1
while true ; do
   if $(echo $status | grep -q 'dapr-system False'); then
      echo "Dapr not ready retry in 30 seconds. Attempts: $attempts"
      sleep 30s
      attempts=$(($attempts + 1))
      status=$(dapr status --kubernetes)
   else
      break
   fi
done

# Install the demo into the cluster
helm install demo3 ./demochart -f ./demochart/mysecrets.yaml \
   --set serviceBus.connectionString=$serviceBusEndpoint \
   --set cognitiveService.token=$cognitiveServiceKey \
   --set cognitiveService.endpoint=$cognitiveServiceEndpoint \
   --set tableStorage.key=$storageAccountKey \
   --set tableStorage.name=$storageAccountName

service=$(kubectl get services viewer --output json)

while true ; do
   if $(echo $service | grep -qE 'ip[^0-9]+[0-9\.]+'); then
      break
   else
      echo "Waiting for IP address retry in 30 seconds."
      sleep 30s
      service=$(kubectl get services viewer --output json)
   fi
done

ip=$(echo $service | grep -oE 'ip[^0-9]+[0-9\.]+' | grep -oE '[0-9\.]+')

echo "Your app is accesable from http://$ip"