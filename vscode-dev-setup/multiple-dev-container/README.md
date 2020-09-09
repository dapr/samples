# Multiple Development Containers

## Overview

This development environment consists of multiple development containers. Each dev container is specialized for developing and debugging a single app. Other dependencies, including Redis and Dapr services, run in containers on the host machine.

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
        -- Node app development container, with VS Code attached
        |
        -- Python app development container, with VS Code attached
```

### Docker Compose

The custom Docker network and the containers for Dapr, Redis, and Zipkin are defined with Docker Compose, which simplifies the provisioning of required containers on the host machine and also ensures that DNS works among all machines on the network so that machines can reference each other by their DNS names. (You could build the same environment using Docker commands instead of Docker Compose.)

## How To Run the Sample

### Prerequisites

Your host machine must be running Docker and Docker Compose. This sample was developed with Docker Compose version 1.26.2.

### Setup

1. Pull this repository to your host machine.
1. Open a terminal window, and navigate to the `multiple-dev-container` folder, where you should see a `docker-compose.yml` file.
1. Run the command `docker-compose up`, which will result in three containers starting:

    - `redis-dev`
    - `zipkin-dev`
    - `dapr-placement-dev`

   > Note: when you run the `docker-compose up` command, your terminal window will pause until you cancel the command (`Ctrl+c` in BASH), but you can also run the command in the background with the `--detach` parameter, as `docker-compose up --detach`. When you are ready to stop the containers, use `docker-compose stop`. However, it is sometimes useful to view the running console output of `docker-compose`.

### Run the node app development container

1. Open VS Code to the `multiple-dev-container/node` folder.

    > IMPORTANT: The folder opened in VS Code must have the `.devcontainer` folder at the root level. Files in that folder define the container VS Code will build and attach to.

    > NOTE: From WSL on Windows, a simple way to open VS Code to the correct folder is to navigate to the folder in a terminal, and type the command `code .` (make sure to include the trailing "`.`" character).

1. From the VS Code command palette (Ctrl+Shift+P), run this command:

    ```ASCII
    Remote-Containers: Reopen in Container
    ```

    VS Code will build the Docker container and attach to the container. The first time the container is built, this command will take some time to pull the local base image and create the container image. Attaching to the container after the first build will be much faster.

    See the files in the `.devcontainer` folder for how the container is defined and configured.

1. When VS Code has attached to the running container, you can press `F5` to build and start debugging.

    When you launch the debugger you will see a terminal window open with the output of the `daprd` task. Click on the `DEBUG CONSOLE` to see the application output. It should look something like this:

    ```ASCII
    /usr/local/bin/node app.js
    Debugger listening on ws://127.0.0.1:41305/c1e69cbe-55fb-46f5-a695-57221e293793
    For help, see: https://nodejs.org/en/docs/inspector
    Debugger attached.
    Node App listening on port 3000!
    ```

    When the python app is started from a separate instance of VS Code (see below for step-by-step instructions), you will see debugging output in the window that looks like this:

    ```ASCII
    /usr/local/bin/node app.js
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

See the files in the `.vscode` folder for details on how debugging is configured.  

Zipkin is running as a container on your host machine, so you can view Zipkin logs in a host machine browser by navigating to [http://localhost:9411](http://localhost:9411).  

Dapr configuration is stored in `.devcontainer/.dapr` so that you can have configuration that is different between a regular deployment and a development container.

### Run the python app development container

The python app is run from a separate instance of VS Code.

1. Open a new instance of VS Code to the `multiple-dev-container/python` folder. (Do not close the instance of VS Code that is attached to the node app development container.)
1. From the VS Code command palette (Ctrl+Shift+P), run this command:

    ```ASCII
    Remote-Containers: Reopen in Container
    ```

1. When VS Code has attached to the running container, you can press `F5` to build and start debugging.

    When you launch the debugger you will see a terminal window open with the output of the `daprd` task. Click on the `DEBUG CONSOLE` to see the application output. It should look something like this:

    ```ASCII
    Sending order 1
    Sending order 2
    Sending order 3
    ```

1. Switch to the instance of VS Code that is running the node app. (The app should be running with the debugger attached.) You should see output like this in the `DEBUG CONSOLE`.

    ```ASCII
    /usr/local/bin/node app.js
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
    