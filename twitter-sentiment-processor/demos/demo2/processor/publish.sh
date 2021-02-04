#!/bin/bash

set -o errexit
set -o pipefail

RELEASE_VERSION='v1.0.0-rc.3'
DOCKER_HUB_USER='darquewarrior'

docker build -t $DOCKER_HUB_USER/processor:$RELEASE_VERSION .

docker push $DOCKER_HUB_USER/processor:$RELEASE_VERSION
