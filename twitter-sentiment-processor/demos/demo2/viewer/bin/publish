#!/bin/bash

set -o errexit
set -o pipefail

go mod tidy

RELEASE_VERSION=v0.3.4

docker build \
  --build-arg APP_VERSION=$RELEASE_VERSION \
  -t darquewarrior/viewer:$RELEASE_VERSION \
  .

docker push darquewarrior/viewer:$RELEASE_VERSION
