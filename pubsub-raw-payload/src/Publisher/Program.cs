using Confluent.Kafka;
using System.Text.Json;
using Shared;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Kafka producer config
var producerConfig = new ProducerConfig
{
    BootstrapServers = "localhost:9092",
    ClientId = "kafka-producer-sample"
};

// Create producer instance
using var producer = new ProducerBuilder<string, string>(producerConfig).Build();

app.MapGet("/", () => "Publisher API");

app.MapPost("/publish", async (HttpContext context) =>
{
    var message = new Message(
        Guid.NewGuid().ToString(),
        $"Hello at {DateTime.UtcNow}",
        DateTime.UtcNow
    );

    try
    {
        // Serialize the message to JSON
        var jsonMessage = JsonSerializer.Serialize(message);

        // Create the Kafka message
        var kafkaMessage = new Message<string, string>
        {
            Key = message.Id,  // Using the message ID as the key
            Value = jsonMessage
        };

        // Publish to Kafka
        var deliveryResult = await producer.ProduceAsync(
            "messages",  // topic name
            kafkaMessage
        );

        Console.WriteLine($"Delivered message to: {deliveryResult.TopicPartitionOffset}");
        return Results.Ok(message);
    }
    catch (ProduceException<string, string> ex)
    {
        Console.WriteLine($"Delivery failed: {ex.Error.Reason}");
        return Results.StatusCode(500);
    }
});

app.Run();

// Ensure proper cleanup
AppDomain.CurrentDomain.ProcessExit += (s, e) => producer?.Dispose();