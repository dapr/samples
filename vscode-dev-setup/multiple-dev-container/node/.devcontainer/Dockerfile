FROM node:14.8.0

# Instructs apt-get to run without a terminal
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    && apt-get dist-upgrade -y

# Install Dapr CLI and init without docker (option "--slim")
RUN curl -sL https://raw.githubusercontent.com/dapr/cli/release-0.11/install/install.sh | bash -
RUN dapr init --slim
ENV PATH=$PATH:/root/.dapr/bin

# Reset to the default value
ENV DEBIAN_FRONTEND=dialog

# VS Code will automatically determine the current folder regardless of this setting, 
# however this will allow connecting to the container from a shell to set the right directory.
# To connect from a shell enter this command: docker exec -it <name or id of container> /bin/bash
WORKDIR /workspaces

# Documentation that the running container should be configured to expose this port
# For this sample there is no front end, so no need to exopose an external port.
# Apps with a user interface will document the port here, and set it in devcontainer.json.
# EXPOSE 8080