package io.dapr.apps.twitter.processor.twitterprocessor.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Sentiment {
   public Sentiment() {
   }

   public Sentiment(String sentiment, float confidence) {
      this.sentiment = sentiment;
      this.confidence = confidence;
   }

   @JsonProperty("sentiment")
   String sentiment;

   @JsonProperty("confidence")
   float confidence;
}