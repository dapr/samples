package io.dapr.apps.twitter.provider.twitterprovider.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Sentiment {
   @JsonProperty("sentiment")
   String sentiment;

   public String getSentiment() {
      return this.sentiment;
   }

   @JsonProperty("confidence")
   float confidence;

   public float getConfidence() {
      return this.confidence;
   }
}