using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using System.Threading;
using System.Text.Json;
using System.Text;
using System.Text.Json.Serialization;

string DAPR_STORE_NAME = "statestore";
var client = new DaprClientBuilder().Build();
for (int i = 1; i <= 2; i++)
{
    var orderId = i;
    var order = new Order(orderId);

    // State transactions operate on raw bytes
    var bytes = JsonSerializer.SerializeToUtf8Bytes(order);
    // Save order transactionally into the state store
    var upsert = new List<StateTransactionRequest>()
    {
        new StateTransactionRequest(orderId.ToString(), bytes, StateOperationType.Upsert)
    };
    await client.ExecuteStateTransactionAsync(DAPR_STORE_NAME, upsert);
    Console.WriteLine("Saving Order: " + order);

    //wait to see the notifications arrive
    await Task.Delay(TimeSpan.FromSeconds(2));

    // Get order from the state store
    var result = await client.GetStateAsync<Order>(DAPR_STORE_NAME, orderId.ToString());
    if (result == null)
        Console.WriteLine("Order not found in store");
    else
        Console.WriteLine($"Retrieved Order: " + result);

    // Delete order transactionally from the state store
    var delete = new List<StateTransactionRequest>()
    {
        new StateTransactionRequest(orderId.ToString(), bytes, StateOperationType.Delete)
    };
    await client.ExecuteStateTransactionAsync(DAPR_STORE_NAME, upsert);
    Console.WriteLine("Deleting Order: " + order);

    //Pause until next order
    await Task.Delay(TimeSpan.FromSeconds(2));
    Console.WriteLine();
}

public record Order([property: JsonPropertyName("orderId")] int orderId);
