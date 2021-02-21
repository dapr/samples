#!/bin/bash

set -o errexit
set -o pipefail

go mod tidy
go build handler.go main.go

dapr run --app-id viewer --app-port 8083 --components-path ../../components --config ../config.yaml --log-level debug -- go run handler.go main.go
