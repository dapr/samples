using System.Text.Json;
using Shared;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Subscriber API");

app.MapGet("/dapr/subscribe", () =>
{
    var subscriptions = new[]
    {
        new
        {
            pubsubname = "pubsub",
            topic = "messages",
            route = "/messages",
            metadata = new Dictionary<string, string>
            {
                { "isRawPayload", "true" }
            }
        }
    };
    return Results.Ok(subscriptions);
});

app.MapPost("/messages", async (HttpContext context) =>
{
    using var reader = new StreamReader(context.Request.Body);
    var json = await reader.ReadToEndAsync();
    Console.WriteLine($"Raw message received: {json}"); // Debug log
    
    try 
    {
        var message = JsonSerializer.Deserialize<Message>(json);
        if (message != null)
        {
            Console.WriteLine($"Received message: {message.Id}");
            Console.WriteLine($"Content: {message.Content}");
            Console.WriteLine($"Timestamp: {message.Timestamp}");
        }
    }
    catch (JsonException ex)
    {
        Console.WriteLine($"Error deserializing message: {ex.Message}");
        return Results.BadRequest("Invalid message format");
    }

    return Results.Ok();
});

app.Run();