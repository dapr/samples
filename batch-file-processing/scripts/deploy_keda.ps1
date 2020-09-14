$resourceGroupName = "<resource-group-name>"
$namespaceName = "<service-bus-namespace-name>"

# Deploy KEDA
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
kubectl create namespace keda
helm install keda kedacore/keda --namespace keda

# Create Authorization Rule for 'batchreceived' topic
az servicebus topic authorization-rule create --resource-group $resourceGroupName --namespace-name $namespaceName --topic-name batchreceived --name kedarule --rights Send Listen Manage

$primaryConnectionString = az servicebus topic authorization-rule keys list --name kedarule --resource-group $resourceGroupName --namespace-name $namespaceName --topic-name batchreceived --query primaryConnectionString --output tsv

Write-Host "base64 representation of the connection string:"
[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($primaryConnectionString))