# Demo 2

This demo requires a cognitive services endpoint in Azure. You can create one manually or use the setup.sh or setup.ps1 files. The use of source is important when using Bash
so the environment variables are properly exported.

Bash

```bash
source setup.sh
```

PowerShell

```powershell
.\setup.ps1
```

## processor

The processor requires two environment variables to be set:

- CS_TOKEN
- CS_ENDPOINT

If you use the setup.sh or setup.ps1 files these values were populated for you. If not be sure and set them before you run the processor.

```shell
dapr run --app-id processor --app-port 3002 --components-path ../components -- node app.js
```

You can also run the ./exec/run files from the processor folder.

```shell
./exec/run.sh
```

## provider

## viewer