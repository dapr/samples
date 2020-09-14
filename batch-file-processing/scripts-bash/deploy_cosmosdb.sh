resourceGroupName="<resource-group-name>"
dbAccountName="<db-account-name>"
dbName="IcecreamDB"
containerName="Orders"

# Create an Azure Cosmos DB database account
az cosmosdb create --name $dbAccountName --resource-group $resourceGroupName

# Create a database
az cosmosdb sql database create --account-name $dbAccountName --resource-group $resourceGroupName --name $dbName

# Create Orders container
az cosmosdb sql container create \
    --account-name $dbAccountName \
    --database-name $dbName \
    --name $containerName \
    --partition-key-path "/id" \
    --resource-group $resourceGroupName

# Copy AccountEndpoint and AccountKey from the output
az cosmosdb keys list -g $resourceGroupName --name $dbAccountName --type connection-strings