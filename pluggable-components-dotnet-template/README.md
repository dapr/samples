# Dapr Pluggable Components Dotnet Template

## Sample info

| Attribute            | Details |
| -------------------- | ------- |
| Dapr runtime version | 1.9.0   |
| Language             | .NET    |
| Environment          | Local   |

## Overview

This is a template project that enables you to build a pluggable statestore component in .NET.

## Run the sample

### Prerequisites

- [.NET Core 6+](https://dotnet.microsoft.com/download)
- [grpc_cli tool](https://github.com/grpc/grpc/blob/master/doc/command_line_tool.md) for making gRPC calls. There are [npm installer](https://www.npmjs.com/package/grpc-cli) and [brew formulae](https://formulae.brew.sh/formula/grpc) available to install.
- Operating system that supports Unix Domain Sockets. UNIX or UNIX-like system (Mac, Linux, or [WSL](https://learn.microsoft.com/windows/wsl/install) for Windows users)

### Step 1 - Clone the sample repository

1. Clone the sample repo, then navigate to the pluggable-components-dotnet-template sample:

```bash
git clone https://github.com/dapr/samples.git
cd samples/pluggable-components-dotnet-sample
```

2. Examine the `./Services/Services.cs` file. You'll see four commented classes. They are `StateStoreService`, `PubSubService`, `InputBindingService` and `OutputBindingService`, their protos are defined inside `./Protos` folder. Uncomment any number of them as these serve as a unimplemented proto service that you start from.

Uncommenting StateStoreService as an example:

```csharp
// Uncomment the lines below to implement the StateStore methods defined in the following protofiles
// ./Protos/dapr/proto/components/v1/state.proto#L123
public class StateStoreService : StateStore.StateStoreBase
{
    private readonly ILogger<StateStoreService> _logger;
    public StateStoreService(ILogger<StateStoreService> logger)
    {
        _logger = logger;
    }
}
```

### Step 2 - Register your unimplemented service

Once you decide which of proto services you are going to implement, go to the `./Program.cs` file and examine the lines 46-50.  You'll see commented lines, uncomment based on the services that you chose to implement.

For registering StateStoreService:

```csharp
// Configure the HTTP request pipeline.
app.MapGrpcService<StateStoreService>(); // Uncomment to register the StateStoreService
// app.MapGrpcService<PubSubService>(); // Uncomment to register the PubSubService
// app.MapGrpcService<InputBindingService>(); // Uncomment to register the InputBindingService
// app.MapGrpcService<OutputBindingService>(); // Uncomment to register the OutputBindingService

```

### Step 3 - Making gRPC requests

1. Run the sample code by running `dotnet run`

2. Based on the previous step you can make calls to any of those services using the `grpc_cli` tool. The example below show how to execute a `Set` on `StateStore` services, but you can apply the same for the others following their proto definitions.

```shell
grpc_cli call unix:///tmp/dapr-components-sockets/my-component.sock dapr.proto.components.v1.StateStore/Set "key:'my_key', value:'my_value'"
```

From now on, you should be able to implement the unimplemented methods from your desired service. Refer to the [official Microsoft documentation for development using Protocol Buffers](https://learn.microsoft.com/aspnet/core/grpc/basics?view=aspnetcore-6.0#c-tooling-support-for-proto-files) for further information.
