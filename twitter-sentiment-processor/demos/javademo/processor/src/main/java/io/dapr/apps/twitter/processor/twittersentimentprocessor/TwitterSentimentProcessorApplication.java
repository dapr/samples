package io.dapr.apps.twitter.processor.twittersentimentprocessor;

import java.net.URI;
import java.util.Optional;
import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.boot.SpringApplication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import io.dapr.apps.twitter.processor.twittersentimentprocessor.model.Text;
import io.dapr.apps.twitter.processor.twittersentimentprocessor.model.Payload;
import io.dapr.apps.twitter.processor.twittersentimentprocessor.model.Sentiment;

@RestController
@SpringBootApplication
public class TwitterSentimentProcessorApplication {

   private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
   private static final String PATH = "text/analytics/v3.0/sentiment?showStats";
   private static final String DAPR_PORT = System.getenv().getOrDefault("DAPR_HTTP_PORT", "35000");
   // Defaults to local development. When in K8s set the environment variable
   // DAPR_SECRET_STORE to `kubernetes`.
   private static final String SECRET_STORE = System.getenv().getOrDefault("DAPR_SECRET_STORE", "secretstore");

   public static void main(String[] args) {
      SpringApplication.run(TwitterSentimentProcessorApplication.class, args);
   }

   @PostMapping("/sentiment")
   public Sentiment tweet(@RequestBody Text text) throws IOException, InterruptedException {
      // The URL endpoint and subscription key are stored as secrets in a Dapr
      // secret store.
      var endpoint = getSecretString("Azure:CognitiveServices:Endpoint");
      var key = getSecretString("Azure:CognitiveServices:SubscriptionKey");

      // Build body for message
      var payload = new Payload();
      payload.documents[0] = text;

      // Because we only send one message per request the id can always be 1
      payload.documents[0].setId("1");

      // Convert our object into JSON to send in request
      var json = OBJECT_MAPPER.writeValueAsString(payload);

      // Call cognitive services
      var client = HttpClient.newHttpClient();
      var body = HttpRequest.BodyPublishers.ofString(json);
      var request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .header("Ocp-Apim-Subscription-Key", key).uri(URI.create(endpoint + PATH)).build();

      HttpResponse<String> response = client.send(request, BodyHandlers.ofString());
      var node = OBJECT_MAPPER.readValue(response.body(), JsonNode.class);

      // Traverse the JSON to pull out the sentiment and the score
      String sentiment = Optional.ofNullable(node).map(n -> n.get("documents")).map(n -> n.get(0))
            .map(n -> n.get("sentiment")).map(n -> n.asText()).orElse("unknown");

      float score = Optional.ofNullable(node).map(n -> n.get("documents")).map(n -> n.get(0))
            .map(n -> n.get("confidenceScores")).map(n -> n.get(sentiment)).map(n -> n.floatValue()).orElse((float) 0);

      return new Sentiment(sentiment, score);
   }

   // This code uses Dapr to get the secrets from any configured secret store
   private String getSecretString(String secret) throws IOException, InterruptedException {
      var jsonResponse = "";

      var client = HttpClient.newHttpClient();
      var request = HttpRequest.newBuilder().GET().header("accept", "application/json")
            .uri(URI.create("http://localhost:" + DAPR_PORT + "/v1.0/secrets/" + SECRET_STORE + "/" + secret)).build();

      HttpResponse<String> response = client.send(request, BodyHandlers.ofString());

      var node = OBJECT_MAPPER.readValue(response.body(), JsonNode.class);
      jsonResponse = Optional.ofNullable(node).map(n -> n.get(secret)).map(n -> n.asText()).orElse("unknown");

      return jsonResponse;
   }
}