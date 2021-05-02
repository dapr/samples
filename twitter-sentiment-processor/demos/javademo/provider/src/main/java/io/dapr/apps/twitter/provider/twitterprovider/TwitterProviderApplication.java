package io.dapr.apps.twitter.provider.twitterprovider;

import java.net.URI;
import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;

import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.http.HttpStatus;
import org.springframework.boot.SpringApplication;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import io.dapr.apps.twitter.provider.twitterprovider.model.State;
import io.dapr.apps.twitter.provider.twitterprovider.model.Tweet;
import io.dapr.apps.twitter.provider.twitterprovider.model.Sentiment;
import io.dapr.apps.twitter.provider.twitterprovider.model.AnalyzedTweet;

@RestController
@SpringBootApplication
public class TwitterProviderApplication {

   private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
   private static final String DAPR_PORT = getEnv("DAPR_HTTP_PORT", "35000");
   private static final String DAPR_ADDRESS = getEnv("DAPR_ADDRESS", "localhost");
   private static final String STATE_URL = String.format("http://%s:%s/v1.0/state/tweet-store", DAPR_ADDRESS,
         DAPR_PORT);
   private static final String PUBLISH_URL = String.format("http://%s:%s/v1.0/publish/tweet-pubsub/tweets",
         DAPR_ADDRESS, DAPR_PORT);
   private static final String SENTIMENT_URL = String.format("http://%s:%s/v1.0/invoke/processor/method/sentiment",
         DAPR_ADDRESS, DAPR_PORT);

   public static void main(String[] args) {
      SpringApplication.run(TwitterProviderApplication.class, args);
   }

   public static String getEnv(String key, String defaultValue) {
      return System.getenv().getOrDefault(key, defaultValue);
   }

   @ResponseBody
   @PostMapping(value = "/tweet")
   @ResponseStatus(HttpStatus.OK)
   public void tweet(@RequestBody Tweet tweet) throws IOException, InterruptedException {
      System.out.printf("Tweet received %s in %s: %s %n", tweet.getId(), tweet.getLanguage(), tweet.getText());

      // Build body for message
      var json = OBJECT_MAPPER.writeValueAsString(tweet);

      // Call Sentiment service
      var client = HttpClient.newHttpClient();
      var body = HttpRequest.BodyPublishers.ofString(json);
      var request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .uri(URI.create(SENTIMENT_URL)).build();

      // Build the analyzed tweet
      HttpResponse<String> response = client.send(request, BodyHandlers.ofString());
      var sentiment = OBJECT_MAPPER.readValue(response.body(), Sentiment.class);
      var analyzedTweet = new AnalyzedTweet(tweet.getId(), tweet, sentiment);

      System.out.printf("Tweet scored %s: %f %n", sentiment.getSentiment(), sentiment.getConfidence());

      // Save the analyzed tweet to the state store
      // The payload for saving state is an array
      State[] states = new State[1];
      states[0] = new State(analyzedTweet.getId(), analyzedTweet);
      json = OBJECT_MAPPER.writeValueAsString(states);
      body = HttpRequest.BodyPublishers.ofString(json);
      request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .uri(URI.create(STATE_URL)).build();
      var stateResponse = client.send(request, BodyHandlers.discarding());

      if (stateResponse.statusCode() > 299) {
         System.out.printf("Error storing state, status code %n", stateResponse.statusCode());
      }

      System.out.printf("Tweet stored %s %n", analyzedTweet.getId());

      // Publish a message
      json = OBJECT_MAPPER.writeValueAsString(analyzedTweet);
      body = HttpRequest.BodyPublishers.ofString(json);
      request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .uri(URI.create(PUBLISH_URL)).build();
      var pubsubResponse = client.send(request, BodyHandlers.discarding());

      if (pubsubResponse.statusCode() > 299) {
         System.out.printf("Error publishing event, status code %n", pubsubResponse.statusCode());
      }

      System.out.printf("Tweet published %s %n", analyzedTweet.getId());
   }
}
