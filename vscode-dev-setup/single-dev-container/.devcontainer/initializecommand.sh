#!/bin/bash

# This script generates the .devcontainer/devcontainer.env file, which contains environment variables for the dev container.
# See devcontainer.json for how this script is invoked.
echo DAPR_REDIS_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dapr_redis) > .devcontainer/devcontainer.env 
echo DAPR_ZIPKIN_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dapr_zipkin) >> .devcontainer/devcontainer.env
echo DAPR_PLACEMENT_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dapr_placement) >> .devcontainer/devcontainer.env