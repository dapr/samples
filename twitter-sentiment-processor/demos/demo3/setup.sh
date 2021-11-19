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

# Progress Spinner
function spinner { 
   local pid=$!
   local spin='-\|/'
   local i=0
   while kill -0 $pid 2>/dev/null; do
      (( i = (i + 1) % 4 ))
      printf '\b%c' "${spin:i:1}"
      sleep .1
   done
   printf ' \r'
}

# Linebreak carriage return
function linebreak {
   printf ' \n '
}
# Get outputs of Azure Deployment
function getOutput {
   echo $(az deployment sub show --name $rgName --query "properties.outputs.$1.value" --output tsv)
}

# Get the IP address of specified Kubernetes service
function getIp {
   kubectl get services $1 --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

# Get the latest version of Kubernetes available in specified location
function getLatestK8s {
   versions=$(az aks get-versions -l $location -o tsv --query="orchestrators[].orchestratorVersion")

   latestVersion=$(printf '%s\n' "${versions[@]}" |
   awk '$1 > m || NR == 1 { m = $1 } END { print m }')

   echo $latestVersion
}

# The name of the resource group to be created. All resources will be place in
# the resource group and start with name.
rgName=$1
rgName=${rgName:-twitterDemo}

# The location to store the meta data for the deployment.
location=$2
location=${location:-eastus}

# The version of the dapr runtime version to deploy.
daprVersion=$3
daprVersion=${daprVersion:-1.3.0}

# The version of k8s control plane
k8sversion=$4
k8sversion=${k8sversion:-$(getLatestK8s)}

# Deploy the infrastructure
az deployment sub create --name $rgName \
   --location $location \
   --template-file ./iac/main.json \
   --parameters rgName=$rgName \
   --parameters location=$location \
   --parameter k8sversion=$k8sversion \
   --output none

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
# Once all the services are running they will all report True instead of False.
# Keep checking the status until you don't find False
linebreak
status=$(dapr status --kubernetes)
while ($(echo $status | grep -q 'dapr-system False')); do
   printf " Dapr starting. Please wait...  "
   sleep 20 &
   spinner
   status=$(dapr status --kubernetes)
done
linebreak
printf " Dapr ready! \n"

# Copy the twitter component file from the demos/components folder to the
# templates folder. Copy this file removes the need for the user to set
# those values second time.
cp -f ../components/twitter.yaml ./demochart/templates/

# Install the demo into the cluster
helm upgrade --install demo3 ./demochart \
   --set serviceBus.connectionString=$serviceBusEndpoint \
   --set cognitiveService.token=$cognitiveServiceKey \
   --set cognitiveService.endpoint=$cognitiveServiceEndpoint \
   --set tableStorage.key=$storageAccountKey \
   --set tableStorage.name=$storageAccountName

# Make sure services are ready
linebreak
until [[ $viewerIp && $zipkinIp ]]
do {
   printf " Getting IP addresses. Please wait...  "
   sleep 20 &
   spinner
   viewerIp=$(getIp 'viewer')
   zipkinIp=$(getIp 'publiczipkin')
}
done

printf "\nYour app is accessible from http://%s\n" $viewerIp
printf "Zipkin is accessible from http://%s\n\n" $zipkinIp
