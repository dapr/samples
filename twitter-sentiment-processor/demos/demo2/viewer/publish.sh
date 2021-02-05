#!/bin/bash

set -o errexit
set -o pipefail

go mod tidy

RELEASE_VERSION='v1.0.0-rc.3'
DOCKER_HUB_USER='darquewarrior'

docker build --build-arg APP_VERSION=$RELEASE_VERSION -t $DOCKER_HUB_USER/viewer:$RELEASE_VERSION .

docker push $DOCKER_HUB_USER/viewer:$RELEASE_VERSION