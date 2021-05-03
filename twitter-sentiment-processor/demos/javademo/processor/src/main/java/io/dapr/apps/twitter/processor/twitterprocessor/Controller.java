package io.dapr.apps.twitter.processor.twitterprocessor;

import java.net.URI;
import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;

import static java.lang.System.out;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import io.dapr.apps.twitter.processor.twitterprocessor.model.Text;
import io.dapr.apps.twitter.processor.twitterprocessor.model.Payload;
import io.dapr.apps.twitter.processor.twitterprocessor.model.Secrets;
import io.dapr.apps.twitter.processor.twitterprocessor.model.Sentiment;

@RestController
public class Controller {
   private static final HttpClient CLIENT = HttpClient.newHttpClient();

   // Use the parse the JSON responses
   private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

   // Defaults to local development. When in K8s set the environment variable
   // DAPR_SECRET_STORE to `kubernetes`.
   private static final String SECRET_STORE = getEnv("SECRET_STORE", "secretstore");
   private static final String DAPR_PORT = getEnv("DAPR_HTTP_PORT", "35000");
   private static final String PATH = "text/analytics/v3.0/sentiment?showStats";
   private static final String DAPR_ADDRESS = getEnv("DAPR_ADDRESS", "localhost");
   private static final String SECRET_KEY = getEnv("SECRET_KEY", "demo-processor-secret");

   // This method does all the work for scoring a tweet. It uses cognitive services from
   // Azure. The URL and Key are stored in secrets and Dapr is used to gain access to them.
   @PostMapping("/sentiment")
   public Sentiment tweet(@RequestBody Text text) throws IOException, InterruptedException {
      // The url endpoint and subscription key are stored as secrets in a Dapr
      // secret store.
      var secrets = getSecretString(SECRET_KEY);

      if (secrets == "" || secrets == "unknown") {
         out.println("secrets = null");
         return null;
      }

      var url = OBJECT_MAPPER.readValue(secrets, Secrets.class);

      out.printf("%s%s%n", url.getEndpoint(), PATH);

      // Build body for message
      var payload = new Payload();
      payload.documents[0] = text;

      // Because we only send one message per request the id can always be 1
      payload.documents[0].setId("1");

      // Convert our object into JSON to send in request
      var json = OBJECT_MAPPER.writeValueAsString(payload);

      out.println(json);

      // Call cognitive services
      var body = HttpRequest.BodyPublishers.ofString(json);
      var request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .header("Ocp-Apim-Subscription-Key", url.getToken()).uri(URI.create(url.getEndpoint() + PATH)).build();

      HttpResponse<String> response = CLIENT.send(request, BodyHandlers.ofString());
      var node = OBJECT_MAPPER.readValue(response.body(), JsonNode.class);

      // Traverse the JSON to pull out the sentiment and the score
      var doc = node.at("/documents").get(0);
      var sentiment = doc.get("sentiment").asText("unknown");
      var score = doc.get("confidenceScores").get(sentiment).asDouble(0);

      out.printf("%s:%f%n", sentiment, score);

      return new Sentiment(sentiment, score);
   }

   private static String getEnv(String key, String defaultValue) {
      return System.getenv().getOrDefault(key, defaultValue);
   }

   // This code uses Dapr to get the secrets from any configured secret store
   private String getSecretString(String secret) throws IOException, InterruptedException {
      var jsonResponse = "";

      var url = String.format("http://%s:%s/v1.0/secrets/%s/%s", DAPR_ADDRESS, DAPR_PORT, SECRET_STORE, secret);

      out.println(url);

      var request = HttpRequest.newBuilder().GET().header("accept", "application/json").uri(URI.create(url)).build();

      try {
         HttpResponse<String> response = CLIENT.send(request, BodyHandlers.ofString());

         if (response.statusCode() > 299) {
            out.printf("error reading secret from Dapr: %n", response.statusCode());
         }

         var node = OBJECT_MAPPER.readValue(response.body(), JsonNode.class);

         // Some secret stores return just the contents of the secret like kubernetes.
         // Others return the secret name as well like the development file based store.
         // Test to see if the secret is in the name or not
         if (node.has(secret)) {
            out.println("Key and data was returned");
            jsonResponse = node.get(secret).asText("unknown");
         } else {
            out.println("Only data was returned");
            jsonResponse = response.body();
         }
      } catch (Exception e) {
         out.println("could not load secret from Dapr");
         out.println(e);
      }

      return jsonResponse;
   }
}
