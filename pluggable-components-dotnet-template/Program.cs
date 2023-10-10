// ------------------------------------------------------------------------
// Copyright 2022 The Dapr Authors
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//     http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ------------------------------------------------------------------------

//Uncomment it import Services.
//using DaprComponents.Services;

var componentName = "my-component"; // replace by your component name
// default directory for components
var socketDir = "/tmp/dapr-components-sockets";
if (!Directory.Exists(socketDir)) // creating directory if it not exists
{
    Directory.CreateDirectory(socketDir);
}
var socket = $"{socketDir}/{componentName}.sock";

if (File.Exists(socket)) // deleting socket in case of it already exists
{
    Console.WriteLine("Removing existing socket");
    File.Delete(socket);
}

var builder = WebApplication.CreateBuilder(args);


// Additional configuration is required to successfully run gRPC on macOS.
// For instructions on how to configure Kestrel and gRPC clients on macOS, visit https://go.microsoft.com/fwlink/?linkid=2099682

// Add services to the container.
builder.WebHost.ConfigureKestrel(options =>
            {
                options.ListenUnixSocket(socket);
            });
builder.Services.AddGrpc();
// gRPC refletion is required for service discovery, do not remove it.
builder.Services.AddGrpcReflection();

var app = builder.Build();

// Configure the HTTP request pipeline.
// app.MapGrpcService<StateStoreService>(); // Uncomment to register the StateStoreService
// app.MapGrpcService<PubSubService>(); // Uncomment to register the PubSubService
// app.MapGrpcService<InputBindingService>(); // Uncomment to register the InputBindingService
// app.MapGrpcService<OutputBindingService>(); // Uncomment to register the OutputBindingService
// app.MapGrpcService<SecretStoreService>(); // Uncomment to register the SecretStoreService

// gRPC refletion is required for service discovery, do not remove it.
app.MapGrpcReflectionService();
app.MapGet("/", () => "Communication with gRPC endpoints must be made through a gRPC client. To learn how to create a client, visit: https://go.microsoft.com/fwlink/?linkid=2086909");

app.Run();
