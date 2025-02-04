namespace Shared;

using System.Text.Json.Serialization;

public record Message(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("content")] string Content,
    [property: JsonPropertyName("timestamp")] DateTime Timestamp
);