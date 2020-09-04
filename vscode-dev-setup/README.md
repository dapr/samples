# VS Code Debugging in Containers

## Sample info

| Attribute | Details |
|--------|--------|
| Dapr runtime version | v0.10 |
| Language | Javascript, Python |
| Environment | Local |

## Overview

This sample demonstrates several possible development environment setups in VS Code for applications that use Dapr. This sample demonstrates several possible development environment configurations for the applications in the `hello-docker-compose` sample, which are based on the applications in the  `hello-world` quickstart. Please review [the sample](https://github.com/dapr/samples/tree/master/hello-docker-compose) and [the quickstart](https://github.com/dapr/quickstarts/tree/master/hello-world) for further information on the application architecture.

## Concepts

Dapr provides a simple way to develop an application built from a single component--install Dapr and your development tools on a machine (physical machine, virtual machine, or container), then debug the application using the Dapr CLI.

If your application is composed of multiple components, especially when multiple platforms and languages are required, then additional setup is needed in order to debug the whole application. For example, if a web application written in node.js is posting messages to Dapr's pub/sub servce, and a separate Python app is processing those messages, you will have to run and debug two separate components. Depending on your application, putting all frameworks and tools on a single development machine may make sense, or you may need to separate each component onto it's own isolated development machine.

VS Code provides flexibility in setting up environments, including the ability to specify a container for development. VS Code will build and attach to the container, which has all the tools installed and configured. When a development container is defined and VS Code debugging configuration is provided, developers can pull the latest source code to their machine, invoke the VS Code command to build and attach to the development container, then press F5 to build and debug the component. This type of configuration minimizes the steps to get developers started, and reduces the variations among developer machines.

For example, this diagram shows one possible development machine topography of a multi-component application.

```ASCII
Host machine (Windows 10, version 2004, with Docker Desktop)
    |
    -- WSL 2: local git repo mounted into development containers
    |
    -- Component 1 dev container, with VS Code attached
    |
    -- Component 2 dev container, with VS Code attached
    |
    -- Dapr placement container
    |
    -- Redis container (state storage and pub/sub)
    |
    -- Dapr zipkin container
```

## Prerequisites and Setup

See the `README` files in each of the subfolders for prerequisites and setup instructions. All examples require a host machine running Docker desktop or Docker CE.

### Windows Host Machine

Required: Windows 10 version 2004 or later

1. Install and configure [Windows Subsystem for Linux version 2](https://docs.microsoft.com/en-us/windows/wsl/) (WSL 2). Install at least one Linux distro in WSL 2.
1. Install Docker Desktop, and enable WSL 2 integration. (Go to Settings --> Resources, and ensure that the "Enable integration with my Default WSL distro" checkbox is checked. If you plan to use an additional distro, enable that one as well.)

### Linux Host Machine

Install and configure Docker CE.

Each subfolder contains a self-contained development environment. The types of environemThis sample has t

- Single container for all applications, no local Docker installation required
- Single container with Docker
- One container for each application, shared Docker 

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
chown abby:abby launch.json
```

### You are prompted to add container configuration files when you already have them.

You try to use an existing container definiton, and you invoke the VS Code command `Remote-Containers: Reopen in Container`, and VS Code prompts you to `Add Development Container Configuration Files` or `Select a container configuration definition`.

You may have opened the wrong folder in VS Code. Make sure that there is a `.devcontainer` folder at the root of your file workspace. The folder should container a file named `devcontainer.json`.

### Having trouble opening VS Code to the right folder in WSL 2

Here is a simple way to open VS Code to the right working folder in WSL 2:

1. Open a WSL 2 terminal session and navigate to the folder where you want VS Code to open.
1. Enter the command `code .` (Make sure you include the trailing `.` character.)

VS Code will launch and open that folder.