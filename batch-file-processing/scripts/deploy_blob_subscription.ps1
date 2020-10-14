# batch-receiver microservice should already be running for the subscription validation handshake
az eventgrid event-subscription create `
    --source-resource-id "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Storage/storageaccounts/<storage-account-name>" `
    --name blob-created `
    --endpoint-type webhook `
    --endpoint https://<FQDN>/api/blobAddedHandler `
    --included-event-types Microsoft.Storage.BlobCreated