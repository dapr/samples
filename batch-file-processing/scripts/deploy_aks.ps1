$subscriptionId = "<subscription-id>"
$resourceGroupName = "<resource-group-name>"
$clusterName = "<cluster-name>"
$location = "<location>" # ex: westus2

az login
az account set -s $subscriptionId
az group create --name $resourceGroupName --location $location
az aks create --resource-group $resourceGroupName --name $clusterName --node-count 2 --kubernetes-version 1.17.9 --enable-addons http_application_routing --generate-ssh-keys --location $location

# Connect to the cluster
az aks get-credentials --resource-group $resourceGroupName --name $clusterName