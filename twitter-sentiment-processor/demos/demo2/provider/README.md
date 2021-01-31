# provider (node version)

Assuming you have Dapr initialized locally and the `processor` service already started:

To start the demo use the command below.

```shell
dapr run --app-id provider --app-port 3001 --components-path ../components -- node app.js
```

You can also start with a script.

PowerShell

```powershell
bin/run.ps1
```

Bash

```bash
bin/run
```