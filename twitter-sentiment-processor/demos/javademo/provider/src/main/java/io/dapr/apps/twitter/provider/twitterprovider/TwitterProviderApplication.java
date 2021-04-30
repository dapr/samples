package io.dapr.apps.twitter.provider.twitterprovider;

import java.net.URI;
import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;

import com.fasterxml.jackson.databind.JsonNode;
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

   private static final String PUBSUB = "messagebus";
   private static final String PUBSUB_TOPIC = "tweets";
   private static final String DAPR_PORT = getDaprPort();
   private static final String STATE_STORE = "statestore";
   private static final String SENTIMENT_PROCESSOR_APP = "processor";

   private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

   public static void main(String[] args) {
      SpringApplication.run(TwitterProviderApplication.class, args);
   }

   public static String getDaprPort() {
      var port = System.getenv("DAPR_HTTP_PORT");
      return (port == null || port.isEmpty()) ? "35000" : port;
   }

   @ResponseBody
   @PostMapping(value = "/tweet")
   @ResponseStatus(HttpStatus.OK)
   public void tweet(@RequestBody Tweet tweet) throws IOException, InterruptedException {
      System.out.printf("Tweet received %s in %s: %s %n", tweet.getId(), tweet.getLanguage(), tweet.getText());

      var baseUrl = "http://localhost:" + DAPR_PORT + "/v1.0/";

      // Build body for message
      var json = OBJECT_MAPPER.writeValueAsString(tweet);

      // Call Sentiment service
      var client = HttpClient.newHttpClient();
      var body = HttpRequest.BodyPublishers.ofString(json);
      var request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .uri(URI.create(baseUrl + "invoke/" + SENTIMENT_PROCESSOR_APP + "/method/sentiment")).build();

      // Build the analyzed tweet
      HttpResponse<String> response = client.send(request, BodyHandlers.ofString());
      var sentiment = OBJECT_MAPPER.readValue(response.body(), Sentiment.class);
      var analyzedTweet = AnalyzedTweet.builder().id(tweet.getId()).tweet(tweet).sentiment(sentiment).build();

      System.out.printf("Tweet scored %s: %f %n", sentiment.getSentiment(), sentiment.getConfidence());

      // Save the analyzed tweet to the state store
      // The payload for saving state is an array
      State[] states = new State[1];
      states[0] = State.builder().key(analyzedTweet.getId()).value(analyzedTweet).build();
      json = OBJECT_MAPPER.writeValueAsString(states);
      body = HttpRequest.BodyPublishers.ofString(json);
      request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .uri(URI.create(baseUrl + "state/" + STATE_STORE)).build();
      var stateResponse = client.send(request, BodyHandlers.discarding());

      System.out.printf("Tweet stored %s %n", analyzedTweet.getId());

      // Publish a message
      json = OBJECT_MAPPER.writeValueAsString(analyzedTweet);
      body = HttpRequest.BodyPublishers.ofString(json);
      request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .uri(URI.create(baseUrl + "publish/" + PUBSUB + "/" + PUBSUB_TOPIC)).build();
      var pubsubResponse = client.send(request, BodyHandlers.discarding());

      System.out.printf("Tweet published %s %n", analyzedTweet.getId());
   }
}
