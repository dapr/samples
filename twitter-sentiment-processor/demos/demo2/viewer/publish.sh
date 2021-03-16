#!/bin/bash

set -o errexit
set -o pipefail

# The name of the docker up user to push images to.
dockerHubUser=$1
dockerHubUser=${dockerHubUser:-darquewarrior}

# The version of the dapr runtime version to use as image tag.
daprVersion=$2
daprVersion=${daprVersion:-1.0.0}

go mod tidy

docker build --build-arg APP_VERSION=$daprVersion -t $dockerHubUser/viewer:$daprVersion .

docker push $dockerHubUser/viewer:$daprVersion
