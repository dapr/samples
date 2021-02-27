#!/bin/bash

# Use this script to publish new images to Docker hub.
# This is not required to complete the demo as images
# have already been pushed to Docker hub.

set -o errexit
set -o pipefail

# The name of the docker up user to push images to.
dockerHubUser=$1
dockerHubUser=${dockerHubUser:-darquewarrior}

# The version of the dapr runtime version to use as image tag.
daprVersion=$2
daprVersion=${daprVersion:-1.0.0}

docker build -t $dockerHubUser/processor:$daprVersion .

docker push $dockerHubUser/processor:$daprVersion
