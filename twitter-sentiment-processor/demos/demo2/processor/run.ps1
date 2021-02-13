npm install

dapr run --app-id processor --app-port 3002 --components-path ../../components --config ../config.yaml --log-level debug -- node ./app.js