# VS Code Development and Debugging for Dapr Applications

## Sample info

| Attribute | Details |
|--------|--------|
| Dapr runtime version | v0.10 |
| Language | Javascript, Python |
| Environment | Local |

## Overview

This sample demonstrates several possible development environment setup configurations in VS Code for applications that use Dapr. The applications used in this sample are from the `hello-docker-compose` sample, which are based on the applications in the  `hello-world` quickstart. Please review [the sample](https://github.com/dapr/samples/tree/master/hello-docker-compose) and [the quickstart](https://github.com/dapr/quickstarts/tree/master/hello-world) for further information on the application architecture.

The goal of all development environment setup is to make developer adoption as simple as possible. A term for this is "The F5 Manifesto", which means that a developer should be able to install minimal dependencies, pull the source repo, and press F5 to build and start debugging. The samples in this section come close to achieving that goal. After configuring your host machine with Docker Desktop or Docker CE, each sample should be debuggable by pulling the source code, running a VS Code command to attach to the development container, and then and pressing F5 from the attached instance of VS Code.

## Concepts

Dapr provides a simple way to develop an application built from a single component: install Dapr and your development tools on a machine (physical machine, virtual machine, or container), then debug the application using the Dapr CLI.

If your application is composed of multiple components, especially when multiple platforms and languages are required, then additional setup is needed in order to debug the whole application. For example, if a web application written in node.js is posting messages to Dapr's pub/sub servce, and a separate Python app is processing those messages, you will have to run and debug two separate components. Depending on your application, putting all frameworks and tools on a single development machine may make sense, or you may need to separate each component onto it's own isolated development machine.

### Development Containers

VS Code provides flexibility in setting up environments, including the ability to specify a container for development. VS Code will build and attach to the container, which has all the necessary tools and platforms installed and configured. When a development container is defined and VS Code debugging configuration is provided, developers can pull the latest source code to their machine, invoke the VS Code command to build and attach to the development container, then press F5 to build and debug the component. This type of configuration minimizes the steps to get developers started, and reduces the variations among developer machines.

For more information, see the VS Code documentation on [developing inside a container](https://code.visualstudio.com/docs/remote/containers)

## Sample Development Configurations

### Single Development Container

This diagram shows a host machine with a single development container, with sidecar containers on the host machine for Dapr placement, Redis, and Dapr metrics (zipkin). The containers for Dapr, Redis, and Zipkin can be quickly created from within the WSL 2 instance (or host machine) by installing the Dapr CLI and running `dapr init`. This development machine configuration may be convenient if all applictions use the same platform technologies. This configuration is not good for applications that use many different platforms and is especially poor for applications in which individual components need to use different versions of a platform.

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
        -- Daprd process for debugging app component 1
        |
        -- Daprd process for debugging app component 2
```

### Single Slim Development Container

This diagram shows a host machine with a single development container, same as the example above, except that all Dapr services are run within the development container. Like the other single development container option, this configuration may be convenient if all applications use the same platform technologies. Having Redis installed in the container simplifies host machine setup, but it increases the complexity of creating the container definition. This configuration is good for applications with a low number of individual components, depending on simple platforms that are expected to be upgraded all at once for the whole application.

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

### Multiple Development Containers

This diagram shows the machine topography of the development environment for a multi-component application. Each application is developed and debugged in its own container. The container definitions are tailored for the individual applications. This configuration is good for systems with many components that need controlled upgrades of platform dependencies.

```ASCII
Host machine (Windows 10, version 2004, with Docker Desktop)
    |
    -- Dapr placement container
    |
    -- Redis container (state storage and pub/sub)
    |
    -- Dapr zipkin container
    |
    -- WSL 2: local git repo
    |
    -- App Component 1 development container, with VS Code attached
        |
        -- Daprd process for debugging app component 1
    |
    -- App Component 2 development container, with VS Code attached
        |
        -- Daprd process for debugging app component 2
```

## Other Possible Development Machine Configurations

VS Code supports many different configuration options. Here are some additional possibilities:

- Windows host machine with WSL 2 and all application components running in WSL 2.
- Cloud-hosted Linux VM running Docker CE with multiple development containers.
- Cloud-hosted development containers (no host machine).

## Prerequisites and Setup

See the `README` files in each of the subfolders in this sample for individual setup instructions for each sample. All examples require a host machine running Docker desktop or Docker CE. Host machine configuration is below.

### Windows Host Machine

Required: Windows 10 version 2004 or later

1. Install and configure [Windows Subsystem for Linux version 2](https://docs.microsoft.com/en-us/windows/wsl/) (WSL 2). Install at least one Linux distro in WSL 2.
1. Install Docker Desktop, and enable WSL 2 integration. (Go to Docker Desktop Settings --> Resources, and ensure that the "Enable integration with my Default WSL distro" checkbox is checked. If you plan to use an additional distro, enable that one as well.)

### Linux Host Machine

Install and configure Docker CE.

Each subfolder contains a self-contained development environment. The types of environemThis sample has t

- Single container for all applications, no local Docker installation required
- Single container with Docker
- One container for each application, shared Docker 

## Other Concepts

### Start a BASH shell instance within a development container

When an instance of VS Code is attached to a running container, there are two options for launching a BASH shell:

- Launch a terminal window within VS Code. The terminal window will be a BASH shell within the container (unless you have configured it to be something else.)
- Use a Docker command from the host machine to run BASH in the container.

This command shows how to launch a container's BASH shell from a host machine terminal:

```BASH
docker exec -it <container name or container ID> /bin/bash
```

When you are finished with the session type `exit` to return to your host machine terminal.

### When the Host Machine is Windows, Use WSL 2

WSL 2 is recommended, but not required, when using Windows as the host machine. By default, VS Code attaches the local source repo to your development container using a Docker file mount. From the Windows file system you may experience slower disk performance when doing IO intensive operations, so one recommendation is to put your source code repo in the WSL 2 file system. See the [VS Code documentation](https://code.visualstudio.com/docs/remote/containers-advanced#_improving-container-disk-performance) for more details and additional options.

## Troubleshooting

### File Permissions

By default development containers are run as root, with the local git workspace mounted in the container. A side effect of running as root is that some files may be owned by the root user.  

The example below shows one file having root ownership. This file was created from within a development container.

```BASH
-rw-r--r-- 1 root  root  1153 Sep  1 15:18 launch.json
-rw-r--r-- 1 abby  abby    47 Sep  1 15:18 settings.json
-rw-r--r-- 1 abby  abby  1202 Sep  1 15:18 tasks.json
```

In this example, attempting to modify `launch.json` from the host machine will result in a permissions error.  

To fix, change the owner back to your regular user using the `chown` command:

```BASH
chown <user>:<group> launch.json
```

### You are prompted to add container configuration files when you already have them.

You try to use an existing container definiton, and you invoke the VS Code command `Remote-Containers: Reopen in Container`, and VS Code prompts you to `Add Development Container Configuration Files` or `Select a container configuration definition`.

You may have opened the wrong folder in VS Code. Make sure there is a `.devcontainer` folder at the root of your file workspace. The folder should container a file named `devcontainer.json`.

### Having trouble opening VS Code to the right folder in WSL 2

Here is a simple way to open VS Code to the right working folder in WSL 2:

1. Open a WSL 2 terminal session and navigate to the folder where you want VS Code to open.
1. Enter the command `code .` (Make sure to include the trailing "`.`" character.)

VS Code will launch and open that folder.

### VS Code debugger launch fails with port conflicts

If one of the dapr-debug tasks fails (see `./.vscode/launch.json`), you may need to kill the daprd process with a manual command. `daprd` is launched as a pre-launch task for debugging the applications, and it is shut down using a separate post-debug task. If an error occurs launching `daprd`, sometimes the post-debug task will not run and `daprd` will continue to run in the background, tying up ports, which prevents `daprd` from launching again. Killing the background instance of `daprd` resolves the problem.

To search for `daprd` background processes, run the following command in a BASH shell (in the development container):

```BASH
ps aux | grep daprd

# returns the result below
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root     20238  2.1  0.2 779704 52604 ?        Sl   01:16   0:00 daprd --app-id pythonapp ... (truncated)
```

If you find a daprd command running, kill it by running `kill <PID>`, where `<PID>` is the process ID for the `daprd` process.

```BASH
kill 20238
```

The `kill` command will send a shutdown signal to `daprd`, which will take a few seconds to shut down.

### A development container becomes misconfigured to the point that it cannot be fixed

One of the great things about developing in a container is that you can delete the container instance (using Docker commands) and start a fresh instance. Source code is attached via Docker bind mounts (by default), so you can delete your container without losing any uncommitted or un-pushed code changes.

1. Close VS Code (or detach from your development container).
1. Run this command to display a list of your containers, both running and stopped. Your development container will stop after you detach VS Code from it.

    ```BASH
    docker ps --all
    ```

1. Remove the container by running this command:

    ```BASH
    docker rm <container name or container ID>
    ```

The next time you invoke the VS Code command to reopen the container (`Remote-Containers: Reopen in Container`) a fresh instance of the container will run for you.

> NOTE: You can also rebuild the container image by invoking the VS Code command `Remote-Containers: Rebuild and Reopen in Container` or from within the container you can run `Remote-Containers: Rebuild Container`, which will rebuild and start the container and re-attach VS Code to it.
> 