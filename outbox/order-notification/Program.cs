using System.Text.Json.Serialization;
using System.Text.Json;

using Dapr;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

// needed for Dapr pub/sub routing
app.MapSubscribeHandler();

if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

//Dapr subscription in [Topic] routes orders topic to this route
app.MapPost("/orders", [Topic("orderpubsub", "orders")] (Order order) =>
{
    Console.WriteLine("Order notification received : " + order.Data);
    return Results.Ok(order);
});

await app.RunAsync();

//public record Order([property: JsonPropertyName("orderId")] int OrderId]);
public record Order
{
    [property: JsonPropertyName("data")]
    public string Data { get; init; }

    public Order(string data)
    {
        Data = data;
    }
}