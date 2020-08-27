echo "Pushing batch-generator image to ACR"

acrLoginServer="<acr-login-server>"
acrName="<acr-name>"

# Log in to the registry
az acr login --name $acrName

# Build an image from a Dockerfile
basedir=$(dirname $BASH_SOURCE)
docker build -t batch-generator:v1 $basedir/../batchGenerator

# Tag the image
docker tag batch-generator:v1 $acrLoginServer/batch-generator:v1

# Push the image to the Azure Container Registry instance
docker push $acrLoginServer/batch-generator:v1
