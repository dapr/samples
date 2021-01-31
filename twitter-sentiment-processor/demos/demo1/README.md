# Demo 1

Make sure you have populated the twitter.yaml file in the components
folder with your twitter information.

## dotnet version (run in provider.net folder)

```powershell
dapr run --app-id producer `
         --app-port 5000 `
         --dapr-http-port 3500 `
         --components-path ../components `
         -- dotnet run

```

```bash
dapr run --app-id producer \
         --app-port 5000 \
         --dapr-http-port 3500 \
         --components-path ../components \
         -- dotnet run

```

## Node.js version (run in provider folder)

Inside of the `provider` directory

```powershell
dapr run --app-id provider `
         --app-port 3001 `
         --dapr-http-port 3500 `
         --components-path ../components `
         -- node app.js
```

```bash
dapr run --app-id provider \
         --app-port 3001 \
         --dapr-http-port 3500 \
         --components-path ../components \
         -- node app.js
```
