echo "Pushing batch-processor image to ACR"

acrLoginServer="<acr-login-server>"
acrName="<acr-name>"

# Log in to the registry
az acr login --name $acrName

# Build an image from a Dockerfile
basedir=$(dirname $BASH_SOURCE)
docker build -t batch-processor:v1 $basedir/../batchProcessor

# Tag the image
docker tag batch-processor:v1 $acrLoginServer/batch-processor:v1

# Push the image to the Azure Container Registry instance
docker push $acrLoginServer/batch-processor:v1