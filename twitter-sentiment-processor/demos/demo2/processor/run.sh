#!/bin/bash

set -o errexit
set -o pipefail

npm install

dapr run --app-id processor --app-port 3002 --components-path ../../components -- node app.js