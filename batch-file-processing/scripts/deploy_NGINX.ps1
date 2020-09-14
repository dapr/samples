$resourceGroup = "<resource-group-name>"
$clusterName = "<aks-name>"

# Choose a name for your public IP address which we will use in the next steps
$publicIpName = "<public-ip-name>"

# Choose a DNS name which we will create and link to the public IP address in the next steps
# Your fully qualified domain name will be: <dns-label>.<location>.cloudapp.azure.com
$dnsName = "<dns-label>"

# Get cluster resource group name
$clusterResourceGroupName = az aks show --resource-group $resourceGroup --name $clusterName --query nodeResourceGroup -o tsv
Write-Host "Cluster Resource Group Name:" $clusterResourceGroupName

# Create a public IP address with the static allocation method in the AKS cluster resource group obtained in the previous steps
$ip = az network public-ip create --resource-group $clusterResourceGroupName --name $publicIpName --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv
Write-Host "IP:" $ip

# Create a namespace for your ingress resources
kubectl create namespace ingress-basic

# Use Helm to deploy an NGINX ingress controller
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update

helm install nginx-ingress stable/nginx-ingress `
    --namespace ingress-basic `
    --set controller.replicaCount=2 `
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux `
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux `
    --set controller.service.loadBalancerIP=$ip `

# Map a DNS name to the public IP
Write-Host "Setting fully qualified domain name (FQDN)..."
$publicIpId = az resource list --name $publicIpName --query [0].id -o tsv
az network public-ip update --ids $publicIpId --dns-name $dnsName

Write-Host "FQDN:"
az network public-ip list --resource-group $clusterResourceGroupName --query "[?name=='$publicIpName'].[dnsSettings.fqdn]" -o tsv

# Copy the domain name, we will need it in the next step.

# It may take a few minutes for the LoadBalancer IP to be available.
# You can watch the status by running 'kubectl get service -l app=nginx-ingress --namespace ingress-basic -w'

# Now you should get "default backend - 404" when sending a request to either IP or Domain name.