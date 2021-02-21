#!/bin/bash

set -o errexit
set -o pipefail

dapr run --app-id provider --app-port 5000 --components-path ../../components/ -- dotnet run