# Demo1
Start the service in Dapr with explicit port so we can invoke it later:

```shell
dapr run --app-id producer --app-port 5000 --port 3501 dotnet run

```

## node.js version 

Inside of the `provider` directory  

```shell
dapr run node app.js \
     --app-id provider \
     --app-port 3001 \
     --protocol http \
     --port 3500
```