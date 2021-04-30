package io.dapr.apps.twitter.provider.twitterprovider.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class State {
   public State(String key, AnalyzedTweet value) {
      this.key = key;
      this.value = value;
   }

   @JsonProperty("key")
   String key;

   @JsonProperty("value")
   AnalyzedTweet value;
}