using System;
using System.Threading;
using System.Threading.Tasks;
using Dapr.Client;

const string DAPR_SECRET_STORE = "demo-secret-store";
const string SECRET_NAME = "dapr";

var client = new DaprClientBuilder().Build();

try {
    var secret = await client.GetSecretAsync(DAPR_SECRET_STORE, SECRET_NAME);
    var secretValue = string.Join(", ", secret);
    Console.WriteLine($"Fetched Secret: {secretValue}");
}
catch {
    Console.WriteLine($"Failed to get the secret.");
}

await Task.Delay(Timeout.InfiniteTimeSpan);
