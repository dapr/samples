# VS Code dev setup scenarios

All configurations have a host machine with Docker Desktop or Docker CE.

# Prerequisites
- Install dapr in WSL and run `dapr init`.

# Container with all apps and dev tools. Dapr runs in CLI.
Name: single-dev-container

- Dapr containers running on Host machine
- One container with all dev tools. 
- Connect multiple VS Code instances to the container, one connected to each app.

## Container defined for each app. Dapr runs in CLI.
Name: multiple-dev-containers

- Host machine with Docker


## Docker compose - start each container with Dev tools loaded and attach
Name: docker-compose

## Kubernetes - 
Name: kubernetes
