# Single Slim Development Container

## Overview

This development environment consists of a single container with all tools and dependencies installed in the container. It is the simplest example to run, but setups like this have the tradeoff of being more complex in the `Dockerfile` container definition and VS Code configuration (`devcontainer.json`).

```ASCII
Host machine (Windows 10, version 2004, with Docker Desktop)
    |
    -- WSL 2: local git repo
    |
    -- Development container for all applications, with VS Code attached
        |
        -- Redis daemon (state storage and pub/sub)
        |
        -- Daprd process for debugging app component 1
            |
            -- Dapr placement service
            |
            -- Dapr metrics service
        |
        -- Daprd process for debugging app component 2
            |
            -- Dapr placement service
            |
            -- Dapr metrics service
```

## How To Run the Sample

1. Pull this repository to your host machine.
1. Open VS Code to the folder that contains this README file.

    > IMPORTANT: The folder opened in VS Code must have the `.devcontainer` folder at the root level. Files in that folder define the container VS Code will build and attach to.

1. From the VS Code command palette (Ctrl+Shift+P), run this command:

    ```
    Remote-Containers: Reopen in Container
    ```

    VS Code will build the Docker container and attach to the container. The first time the container is built, this command will take some time to pull the local base image and create the container image. Attaching to the container after the first build will be much faster.

    > See the files in the `.devcontainer` folder for how the container is defined and configured.

1. When VS Code has attached to the running container, you can press `F5` to build and start debugging.

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
