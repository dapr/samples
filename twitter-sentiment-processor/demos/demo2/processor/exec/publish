#!/bin/bash

set -o errexit
set -o pipefail

RELEASE_VERSION=v0.3.4

docker build -t darquewarrior/processor:$RELEASE_VERSION .

docker push darquewarrior/processor:$RELEASE_VERSION

# docker run -it -p 3002:3002 -d darquewarrior/processor:$RELEASE_VERSION
