package io.dapr.apps.twitter.provider.twitterprovider.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class AnalyzedTweet {
   public AnalyzedTweet(String id, Tweet tweet, Sentiment sentiment) {
      this.id = id;
      this.tweet = tweet;
      this.sentiment = sentiment;
   }

   @JsonProperty("id")
   String id;

   public String getId() {
      return this.id;
   }

   @JsonProperty("tweet")
   Tweet tweet;

   @JsonProperty("sentiment")
   Sentiment sentiment;
}