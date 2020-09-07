#!/bin/bash

# This script runs in the dev container and updates the hosts file.
# It depends on environment variables being set in the container.
# See devcontainer.json for how this script is invoked.
echo "$DAPR_REDIS_IP	dapr_redis" >> /etc/hosts
echo "$DAPR_ZIPKIN_IP	dapr_zipkin" >> /etc/hosts
echo "$DAPR_PLACEMENT_IP	dapr_placement" >> /etc/hosts