npm install

dapr run --app-id provider --app-port 3001 --components-path ../../components --config ../config.yaml --log-level debug -- node app.js