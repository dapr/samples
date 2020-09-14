# Single Development Container

## Overview

This development environment consists of a single container with development tools and dependencies installed in the container. Other dependencies, including Redis and Dapr services, run in containers on the host machine. The development container is simpler than the [slim sample](../single-dev-container-slim/README.md) because it does not have Redis installed, but the tradeoff is that the development container needs DNS name resolution to Redis and the other Dapr containers. Also, this configuration takes advantage of the Zipkin container created by Dapr on the host machine for viewing logs.

```ASCII
Host machine (Windows 10, version 2004, with Docker Desktop)
    |
    -- WSL 2: local git repo
    |
    -- Custom Docker network
        |
        -- Dapr placement container
        |
        -- Redis container (state storage and pub/sub)
        |
        -- Dapr zipkin container
        |
        -- Development container for all applications, with VS Code attached
            |
            -- Node app
            |
            -- Python app
```

### DNS Name Resolution to Dapr Containers

The Dapr CLI has an excellent feature that creates Dapr support containers on your machine (Redis, Zipkin, Dapr placement) when you run `dapr init`, however, the containers created by `dapr init` cannot be used from a development container because Docker does not provide DNS name resolution between containers for its default network. In this sample, similar containers are created from the same images used by `docker init`, but they are added to a custom Docker network, which provides DNS name resolution between containers.

If you prefer, this sample will work with the default Dapr support containers, but you will have to modify the development container configuration to use the IP addresses of the support containers, or add entries to the development container's `/etc/hosts` file. Container IP addresses may change, so this configuration will have to be reapplied every time the host machine reboots.

## How To Run the Sample

### Prerequisites

Your host machine must be running Docker and Docker Compose. This sample was developed with Docker Compose version 1.26.2.

### Setup

1. Pull this repository to your host machine.
1. Open a terminal window, and navigate to the `single-dev-container` folder, where you should see a `docker-compose.yml` file.
1. Run the command `docker-compose up`, which will result in three containers starting:

   - `dapr-placement-dev-single`
   - `redis-dev-single`
   - `zipkin-dev-single`
  
   > Note: when you run the `docker-compose up` command, your terminal window will pause until you cancel the command (`Ctrl+C` in BASH), but you can also run the command in the background with the `--detach` parameter, as `docker-compose up --detach`. When you are ready to stop the containers, use `docker-compose stop`. However, it is sometimes useful to view the running console output of `docker-compose`.

### Step-by-step

1. Open VS Code to the `multiple-dev-container/node` folder.

    > IMPORTANT: The folder opened in VS Code must have the `.devcontainer` folder at the root level. Files in that folder define the container VS Code will build and attach to.

    > NOTE: From WSL on Windows, a simple way to open VS Code to the correct folder is to navigate to the folder in a terminal, and type the command `code .` (make sure to include the trailing "`.`" character).


1. From the VS Code command palette (Ctrl+Shift+P), run this command:

    ```ASCII
    Remote-Containers: Reopen in Container
    ```

    VS Code will build the Docker container and attach to the container. The first time the container is built, this command will take some time to pull the local base image and create the container image. Attaching to the container after the first build will be much faster.

    See the files in the `.devcontainer` folder for how the container is defined and configured.

2. When VS Code has attached to the running container, you can press `F5` to build and start debugging.
3. Zipkin is running as a container on your host machine, so you can view Zipkin logs in a host machine browser by navigating to [http://localhost:9411](http://localhost:9411).

See the files in the `.vscode` folder for details on how debugging is configured.

## Debugging Configuration

The launch configuration allows you to run both applications with a debugger attached within the development container. Three launch configurations exist:

- Debug All
- Node App
- Python App

You can debug the apps individually, or debug one app and then launch the debugger for the second app, or run the composite command `Debug All` to debug both.

Output is in the `DEBUG CONSOLE` pane of the VS Code command window. (You can configure output to appear in the `TERMINAL` pane if you prefer.) It should look like the output below.

```BASH
/usr/local/bin/node ./node/app.js
Debugger listening on ws://127.0.0.1:41305/c1e69cbe-55fb-46f5-a695-57221e293793
For help, see: https://nodejs.org/en/docs/inspector
Debugger attached.
Node App listening on port 3000!
Got a new order! Order ID: 1
Successfully persisted state.
Got a new order! Order ID: 2
Successfully persisted state.
Got a new order! Order ID: 3
Successfully persisted state.
```

Dapr configuration is stored in `.devcontainer/.dapr` so that you can have configuration that is different between a regular deployment and a development container.
