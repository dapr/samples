echo "Pushing batch-receiver image to ACR"

acrLoginServer="<acr-login-server>"
acrName="<acr-name>"

# Log in to the registry
az acr login --name $acrName

# Build an image from a Dockerfile
basedir=$(dirname $BASH_SOURCE)
docker build -t batch-receiver:v1 $basedir/../batchReceiver

# Tag the image
docker tag batch-receiver:v1 $acrLoginServer/batch-receiver:v1

# Push the image to the Azure Container Registry instance
docker push $acrLoginServer/batch-receiver:v1