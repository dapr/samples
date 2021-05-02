package io.dapr.apps.twitter.processor.twitterprocessor;

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

import io.dapr.apps.twitter.processor.twitterprocessor.model.Text;
import io.dapr.apps.twitter.processor.twitterprocessor.model.Payload;
import io.dapr.apps.twitter.processor.twitterprocessor.model.Sentiment;

@RestController
@SpringBootApplication
public class TwitterProcessorApplication {

   private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
   private static final String PATH = "text/analytics/v3.0/sentiment?showStats";
   private static final String DAPR_PORT = getEnv("DAPR_HTTP_PORT", "35000");
   // Defaults to local development. When in K8s set the environment variable
   // DAPR_SECRET_STORE to `kubernetes`.
   private static final String SECRET_STORE = getEnv("SECRET_STORE", "secretstore");
   private static final String SECRET_STORE_NAMESPACE = getEnv("SECRET_STORE_NAMESPACE", "");
   private static final String ENDPOINT_KEY = getEnv("ENDPOINT_KEY", "Azure:CognitiveServices:Endpoint");
   private static final String SECRET_KEY = getEnv("SECRET_KEY", "Azure:CognitiveServices:SubscriptionKey");

   public static void main(String[] args) {
      SpringApplication.run(TwitterProcessorApplication.class, args);
   }

   public static String getEnv(String key, String defaultValue) {
      return System.getenv().getOrDefault(key, defaultValue);
   }

   @PostMapping("/sentiment")
   public Sentiment tweet(@RequestBody Text text) throws IOException, InterruptedException {
      // The URL endpoint and subscription key are stored as secrets in a Dapr
      // secret store.
      var key = getSecretString(SECRET_KEY);
      var endpoint = getSecretString(ENDPOINT_KEY);

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

      var url = String.format("http://localhost:%s/v1.0/secrets/%s/%s", DAPR_PORT, SECRET_STORE, secret);

      System.out.println(url);

      var client = HttpClient.newHttpClient();
      var request = HttpRequest.newBuilder().GET().header("accept", "application/json")
            .uri(URI.create(url)).build();

      HttpResponse<String> response = client.send(request, BodyHandlers.ofString());

      var node = OBJECT_MAPPER.readValue(response.body(), JsonNode.class);
      jsonResponse = Optional.ofNullable(node).map(n -> n.get(secret)).map(n -> n.asText()).orElse("unknown");

      return jsonResponse;
   }
}