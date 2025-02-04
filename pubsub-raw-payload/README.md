# Consuming Kafka messages without CloudEvents

## Sample info

| Attribute | Details |
|--------|--------|
| Dapr runtime version | v1.14.4 |
| Dapr .NET SDK | v1.14.0 |
| Language | C# |
| Environment | Local |

## Overview

This sample demonstrates how to integrate a Kafka producer using the Confluent Kafka SDK with a Dapr-powered consumer in .NET applications. The producer publishes messages directly to Kafka, while the consumer uses Dapr's pub/sub building block to receive them. These messages are not wrapped as CloudEvents, which is the default Dapr behaviour when publishing/subscribing to messages.

You can find more details about publishing & subscribing messages without CloudEvents [here](https://docs.dapr.io/developing-applications/building-blocks/pubsub/pubsub-raw).

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download)
- [Dapr CLI](https://docs.dapr.io/getting-started/install-dapr-cli/)
- [Docker](https://www.docker.com/products/docker-desktop)

## Setup

1. Clone the repository
2. Navigate to the solution folder:

```bash
cd pubsub-raw-payload
```

3. Start Kafka using Docker Compose:

```bash
docker-compose up -d
```

## Running the Applications

1. Start the Dapr Subscriber:

```bash
dapr run --app-id subscriber \
         --app-port 5001 \
         --dapr-http-port 3501 \
         --resources-path ./components \
         -- dotnet run --project src/Subscriber/Subscriber.csproj
```

2. In a new terminal, start the Kafka Publisher:

```bash
dotnet run --project src/Publisher/Publisher.csproj
```

## Subscription Configuration

### Programmatic Subscription

The subscriber uses programmatic subscription configured in code:

```csharp
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
```

### Declarative Subscription

Alternatively, create a `subscription.yaml` in your components directory:

```yaml
apiVersion: dapr.io/v2alpha1
kind: Subscription
metadata:
  name: message-subscription
spec:
  topic: messages
  routes:
    default: /messages
  pubsubname: pubsub
  metadata:
    isRawPayload: "true"
```

When using declarative subscriptions:

1. Remove the `/dapr/subscribe` endpoint from your subscriber application
2. Place the `subscription.yaml` file in your components directory
3. The subscription will be automatically loaded when you start your application

## Testing

To publish a message:

```bash
curl -X POST http://localhost:5000/publish
```

The subscriber will display received messages in its console output.

## Stopping the Applications

1. Stop the running applications using Ctrl+C in each terminal
2. Stop Kafka:

```bash
docker-compose down
```

## Important Notes

1. The `isRawPayload` attribute is required for receiving raw JSON messages in .NET applications
2. The publisher uses the Confluent.Kafka client directly to publish messages to Kafka
3. The subscriber uses Dapr's pub/sub building block to consume messages
4. Make sure your Kafka broker is running before starting the applications