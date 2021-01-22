# Demo 1

Start the service in Dapr with explicit port so we can invoke it later:

## dotnet version

```shell
dapr run --app-id producer --app-port 5000 --dapr-http-port 3500 -- dotnet run

```

## Node.js version

Inside of the `provider` directory

```shell
dapr run --app-id provider \
         --app-port 3001 \
         --dapr-http-port 3500 \
         -- node app.js
```
