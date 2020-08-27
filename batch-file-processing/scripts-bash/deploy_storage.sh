storageAccountName="<storage-account-name>"
resourceGroupName="<resource-group-name>"
location="<location>"
sasExpirationDate="<YYYY-MM-DD>"

echo "Creating storage account..."
az storage account create \
    --name $storageAccountName \
    --resource-group $resourceGroupName \
    --location $location \
    --sku Standard_RAGRS \
    --kind StorageV2
    
echo "Creating blob container..."
az storage container create \
    --name orders \
    --account-name $storageAccountName \
    --auth-mode login
    
echo "Generating SAS..."
az storage account generate-sas \
    --account-name $storageAccountName \
    --expiry $sasExpirationDate \
    --https-only \
    --permissions rwdlacup \
    --resource-types sco \
    --services bfqt
    
echo "Getting storage account access keys..."
az storage account keys list --account-name $storageAccountName