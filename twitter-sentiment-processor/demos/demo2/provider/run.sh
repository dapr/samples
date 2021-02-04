#!/bin/bash

set -o errexit
set -o pipefail

npm install

dapr run --app-id provider --app-port 3001 --components-path ../../components -- node app.js