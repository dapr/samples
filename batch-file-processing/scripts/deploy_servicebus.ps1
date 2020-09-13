$resourceGroupName = "<resource-group-name>"
$namespaceName = "<service-bus-namespace-name>"
$location = "<location>"

az servicebus namespace create `
    --name $namespaceName `
    --resource-group $resourceGroupName `
    --location $location `
    --sku Standard

# Create topic
az servicebus topic create --name batchreceived `
                           --namespace-name $namespaceName `
                           --resource-group $resourceGroupName

# Get the connection string for the namespace
$connectionString=$(az servicebus namespace authorization-rule keys list --resource-group $resourceGroupName --namespace-name $namespaceName --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)
Write-Host "Connection String:" $connectionString