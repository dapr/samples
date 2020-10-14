FROM node:14.8.0

# Instructs apt-get to run without a terminal
ENV DEBIAN_FRONTEND=noninteractive

# Install Redis. See https://redis.io/topics/quickstart
# NOTE: Redis will not start automatically because systemd is not included in the container.
#       Redis startup is configured in the devcontainer.json file, or it can be started
#       from a bash shell within the container by running '/etc/init.d/redis_6379 start'.
RUN wget http://download.redis.io/redis-stable.tar.gz \
    && tar xvzf redis-stable.tar.gz \
    && cd redis-stable \
    && make \
    && make install \
    && mkdir /etc/redis \
    && mkdir /var/redis \
    && cp utils/redis_init_script /etc/init.d/redis_6379 \
    && cp redis.conf /etc/redis/6379.conf \
    && mkdir /var/redis/6379 \
    && sed -i "s/^\(daemonize *\).*/\1yes/" /etc/redis/6379.conf \
    && sed -i "s/^\(pidfile *\).*/\1\/var\/run\/redis_6379.pid/" /etc/redis/6379.conf \
    && sed -i "s/^\(pidfile *\).*/\1\/var\/log\/redis_6379.log/" /etc/redis/6379.conf \
    && sed -i "s/^\(pidfile *\).*/\1\/var\/redis\/6379/" /etc/redis/6379.conf \
    && update-rc.d redis_6379 defaults \
    && cd ..

# Install Python3 and pip3
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog python3-all-dev python3-pip 2>&1 \
    && apt-get dist-upgrade -y

# Install pylint
RUN pip3 install --upgrade setuptools \
    && pip3 install wheel \
    && pip3 install ez_setup pylint requests

# Install Dapr CLI and init without docker (option "--slim")
RUN curl -sL https://raw.githubusercontent.com/dapr/cli/release-0.11/install/install.sh | bash -
RUN dapr init --slim
ENV PATH=$PATH:/root/.dapr/bin

# Reset to the default value
ENV DEBIAN_FRONTEND=dialog

# VS Code will automatically determine the current folder regardless of this setting, 
# however this will allow connecting to the container from a shell to set the right directory.
# To connect from a shell enter this command: docker exec -it <name or id of container> /bin/bash
WORKDIR /workspaces/samples/vscode-dev-setup/single-dev-container

# Documentation that the running container should be configured to expose this port
# For this sample there is no front end, so no need to exopose an external port.
# Apps with a user interface will document the port here, and set it in devcontainer.json.
# EXPOSE 8080