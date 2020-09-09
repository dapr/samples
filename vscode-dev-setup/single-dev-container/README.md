# Single Development Container



NOTE: The Dapr CLI has an excellent feature that creates containers on your machine when you run `dapr init`. It creates supporting containers for Redis, Zipkin, and Dapr placement. These are great for developing and testing from your host machine, but if you are developing within a container then these supporting containers are not addressible by their DNS names because Docker does not provide DNS services among containers on the Docker default network. In this sample, similar containers are created from the same images, but added to a custom Docker network, which provides DNS name resolution between containers. If you perfer, this sample will work with the default Dapr support containers, but you will have to modify the development container configuration to use the IP addresses of the support containers, or add entries to the development container's `/etc/hosts` file. Container IP addresses may change, so this configuration will have to be reapplied every time the host machine reboots.




## Overview

This development environment consists of a single container with development tools and dependencies installed in the container. Other dependencies, including Redis and Dapr services, run in containers on the host machine. The development container is simpler than the [slim sample](../single-dev-container-slim/README.md) because it does not have Redis installed, but the tradeoff is that the development container needs DNS name resolution to Redis and the other Dapr containers. Also, this configuration takes advantage of the Zipkin container created by Dapr on the host machine for viewing logs.

```ASCII
Host machine (Windows 10, version 2004, with Docker Desktop)
    |
    -- WSL 2: local git repo
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

The development container has Dapr configurations and debugging configurations that refer to the Redis and Dapr containers by DNS name. (See below: the Redis and Dapr containers are created on the host machine by running the `dapr init` CLI command.)

When the host machine reboots or Docker is restarted, the Dapr containers may get new IP addresses. (And Docker does not provide DNS services.) Therefore, the IP addresses of the Dapr containers cannot be known to the development container until all containers have started.

To provide DNS name resolution to the development container, this sample injects entries into the development container's `/etc/hosts` file using these elements:

- The `devcontainer.json` file invokes an `initializeCommand` that runs the shell script `initializecommand.sh`.
- `initializecommand.sh` generates a file named `devcontainer.env` which stores a list of environment variables to be injected into the development container. The environment variables are the IP addresses of the Dapr containers.
- The `devcontainer.json` file has a `runArgs` setting that passes `devcontainer.env` as an argument to the `docker run` command when the development container starts, which instructs Docker to add the environment variables to the development container.
- The `devcontainer.json` file has a `postAttachCommand` configured that runs after VS Code attaches to the container. The command runs the `postattachcommand.sh` script within the container, which adds entries to the `/etc/hosts` file, allowing the development container to address the Dapr containers by name instead of IP address.

> Note: an alternate solution to provide DNS name resolution could be to run the Dapr containers using Docker Compose and specify that the Dapr containers are sidecar containers to the development container. Sidecar containers share a single networking stack, therefore all services exposed by all containers would be available as `localhost` addresses from the development container. However, the solution in this sample was chosen to allow the Dapr containers to run as-is after running `dapr init`.

## How To Run the Sample

### Prerequisites

Verify that your host machine is running the Dapr development containers. The command `docker ps` should show at least these containers running on your host machine:

```ASCII
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                              NAMES
<container id>      daprio/dapr         "./placement"            2 weeks ago         Up 6 minutes        0.0.0.0:50005->50005/tcp           dapr_placement
<container id>      redis               "docker-entrypoint.s…"   2 weeks ago         Up 6 minutes        0.0.0.0:6379->6379/tcp             dapr_redis
<container id>      openzipkin/zipkin   "/busybox/sh run.sh"     2 weeks ago         Up 6 minutes        9410/tcp, 0.0.0.0:9411->9411/tcp   dapr_zipkin
```

If you do not see these containers running, [install the dapr CLI](https://github.com/dapr/docs/blob/master/getting-started/environment-setup.md) and set up Dapr for self-hosted mode by running `dapr init`. The `dapr init` command will create the containers for you and initialize the Dapr runtime for self-hosted mode. 

> Note: on Windows 10, `dapr init` can be run from a PowerShell or CMD window, or it can be run from WSL 2 if WSL integration is enabled in Docker.

This sample requires that you start VS Code from WSL or Linux because it depends on a Linux shell command that runs before the development container is built. (You could create a Windows version of this command if you prefer.) The command is at `.devcontainer/initializecommand.sh`.

### Step-by-step

1. Pull this repository to your host machine. As described above, the repository must be on WSL or Linux for this sample to run.
1. Open VS Code to the folder that contains this README file.

    > IMPORTANT: The folder opened in VS Code must have the `.devcontainer` folder at the root level. Files in that folder define the container VS Code will build and attach to.

1. From the VS Code command palette (Ctrl+Shift+P), run this command:

    ```ASCII
    Remote-Containers: Reopen in Container
    ```

    VS Code will build the Docker container and attach to the container. The first time the container is built, this command will take some time to pull the local base image and create the container image. Attaching to the container after the first build will be much faster.

    See the files in the `.devcontainer` folder for how the container is defined and configured.

1. When VS Code has attached to the running container, you can press `F5` to build and start debugging.
1. Zipkin is running as a container on your host machine, so you can view Zipkin logs in a host machine browser by navigating to [http://localhost:9411](http://localhost:9411).

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

## Troubleshooting

### When building the container you get permission errors on the initialize scripts

Check the ownership of the initialize scripts at `.devcontainer/initializecommand.sh` and `.devcontainer/postattachcommand.sh`. You should have execute permissions. If not, fix the permissions with `chmod` and `chown` commands:

```BASH
sudo chown <user>:<group> initializecommand.sh postattachcommand.sh
sudo chmod +x initializecommand.sh postattachcommand.sh
```
