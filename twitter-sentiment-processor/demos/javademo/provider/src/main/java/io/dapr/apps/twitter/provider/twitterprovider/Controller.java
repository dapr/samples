package io.dapr.apps.twitter.provider.twitterprovider;

import java.net.URI;
import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse.BodyHandlers;

import static java.lang.System.out;

import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import io.dapr.apps.twitter.provider.twitterprovider.model.State;
import io.dapr.apps.twitter.provider.twitterprovider.model.Tweet;
import io.dapr.apps.twitter.provider.twitterprovider.model.Sentiment;
import io.dapr.apps.twitter.provider.twitterprovider.model.AnalyzedTweet;

@RestController
public class Controller {
   private static final HttpClient CLIENT = HttpClient.newHttpClient();
   private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
   private static final String DAPR_PORT = getEnv("DAPR_HTTP_PORT", "35000");
   private static final String DAPR_ADDRESS = getEnv("DAPR_ADDRESS", "localhost");
   private static final String STATE_URL = String.format("http://%s:%s/v1.0/state/tweet-store", DAPR_ADDRESS,
         DAPR_PORT);
   private static final String PUBLISH_URL = String.format("http://%s:%s/v1.0/publish/tweet-pubsub/tweets",
         DAPR_ADDRESS, DAPR_PORT);
   private static final String SENTIMENT_URL = String.format("http://%s:%s/v1.0/invoke/processor/method/sentiment",
         DAPR_ADDRESS, DAPR_PORT);

   // This method does all the work of receiving tweets from the Dapr input
   // binding.
   // Because named the Twitter binding component "tweets" we must provide a
   // "tweets"
   // route that accepts a POST request.
   // The Tweet class is used to make the JSON a POJO.
   // The traceparent header is needed to tie all the request from the provider
   // together for tracing.
   @ResponseBody
   @PostMapping(value = "/tweets")
   @ResponseStatus(HttpStatus.OK)
   public void tweet(@RequestBody Tweet tweet, @RequestHeader(value = "traceparent") String traceparent)
         throws IOException, InterruptedException {
      out.printf("Tweet received %s in %s: %s %n", tweet.getId(), tweet.getLanguage(), tweet.getText());

      // Build body for message
      var json = OBJECT_MAPPER.writeValueAsString(tweet);

      // Call Sentiment service
      var body = HttpRequest.BodyPublishers.ofString(json);
      var request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .header("traceparent", traceparent).uri(URI.create(SENTIMENT_URL)).build();

      out.println("Send tweet to be scored");
      var response = CLIENT.send(request, BodyHandlers.ofString());

      if (response.statusCode() > 299) {
         out.printf("Error call sentiment service: %n", response.statusCode());
         return;
      }

      var sentiment = OBJECT_MAPPER.readValue(response.body(), Sentiment.class);

      // Build the analyzed tweet
      var analyzedTweet = new AnalyzedTweet(tweet.getId(), tweet, sentiment);

      out.printf("Tweet scored %s: %f %n", sentiment.getSentiment(), sentiment.getConfidence());

      // Save the analyzed tweet to the state store
      // The payload for saving state is an array
      var states = new State[1];
      states[0] = new State(analyzedTweet.getId(), analyzedTweet);
      json = OBJECT_MAPPER.writeValueAsString(states);
      body = HttpRequest.BodyPublishers.ofString(json);
      request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .header("traceparent", traceparent).uri(URI.create(STATE_URL)).build();
      var stateResponse = CLIENT.send(request, BodyHandlers.discarding());

      if (stateResponse.statusCode() > 299) {
         out.printf("Error storing state, status code %n", stateResponse.statusCode());
      }

      out.printf("Tweet stored %s %n", analyzedTweet.getId());

      // Publish a message
      json = OBJECT_MAPPER.writeValueAsString(analyzedTweet);
      body = HttpRequest.BodyPublishers.ofString(json);
      request = HttpRequest.newBuilder().POST(body).header("Content-Type", "application/json")
            .header("traceparent", traceparent).uri(URI.create(PUBLISH_URL)).build();
      var pubsubResponse = CLIENT.send(request, BodyHandlers.discarding());

      if (pubsubResponse.statusCode() > 299) {
         out.printf("Error publishing event, status code %n", pubsubResponse.statusCode());
      }

      out.printf("Tweet published %s %n", analyzedTweet.getId());
   }

   private static String getEnv(String key, String defaultValue) {
      return System.getenv().getOrDefault(key, defaultValue);
   }
}
