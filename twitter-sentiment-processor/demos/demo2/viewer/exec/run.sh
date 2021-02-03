#!/bin/bash

set -o errexit
set -o pipefail

go mod tidy

dapr run --app-id viewer --app-port 8083 -- go run handler.go main.go
