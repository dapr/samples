#!/bin/bash

set -o errexit
set -o pipefail

RELEASE_VERSION=v0.3.4
DOCKER_HUB_USER=darquewarrior

docker build -t $DOCKER_HUB_USER/provider:$RELEASE_VERSION .

docker push $DOCKER_HUB_USER/provider:$RELEASE_VERSION

# docker run -it -p 3001:3001 -d $DOCKER_HUB_USER/provider:$RELEASE_VERSION
